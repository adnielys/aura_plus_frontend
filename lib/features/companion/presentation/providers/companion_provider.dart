import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../crisis/domain/crisis_resource.dart';

/// Un turno de la conversación. `role` distingue quién habló: ella, el
/// modelo, o una plantilla del servidor (crisis / degradación) — las dos
/// últimas se pintan IGUAL: para ella es Aura, no un mecanismo.
typedef CompanionTurn = ({
  String id,
  String role,
  String content,
  // Teléfonos llamables que acompañan a una plantilla de crisis. Vacío en
  // todo lo demás. El número YA va escrito dentro de `content`: esto es una
  // mejora encima, jamás el único sitio donde vive (SPEC_RECURSOS_CRISIS §1).
  List<CrisisResource> resources,
});

/// Lo que responde `POST /companion/message`. `suggestedAction` la decide el
/// SERVIDOR (nunca el texto del modelo) y aquí solo se pinta como invitación.
typedef CompanionReply = ({
  String reply,
  String replyKind,
  String? suggestedAction,
  List<CrisisResource> resources,
});

bool _isMine(String role) => role == 'user';

/// Historial de la conversación activa. Lista vacía si el acompañante está
/// apagado (404): la app JAMÁS depende de él.
final companionHistoryProvider =
    FutureProvider<List<CompanionTurn>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<Object?>('/companion/history');
    final body = unwrapEnvelope(response.data);
    return [
      for (final item in (body as List? ?? const []))
        (
          id: (item as Map)['id'] as String,
          role: (item['role'] as String?) ?? 'assistant',
          content: (item['content'] as String?) ?? '',
          // La conversación pasada se relee como texto: los botones son para
          // el momento, no para el archivo.
          resources: const <CrisisResource>[],
        ),
    ];
  } on ApiException {
    return const [];
  } on DioException {
    return const [];
  }
});

/// true = el acompañante está disponible (flag encendida en el servidor).
/// La puerta del Home solo aparece si lo está — sin promesas vacías.
final companionAvailableProvider = FutureProvider<bool>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    await dio.get<Object?>('/companion/history');
    return true;
  } catch (_) {
    return false;
  }
});

/// Envía un mensaje. Devuelve null si no se pudo (sin red, apagado): la UI
/// lo dice con calma y el texto de ella no se pierde.
Future<CompanionReply?> sendCompanionMessage(
  WidgetRef ref, {
  required String text,
}) async {
  try {
    final response = await ref.read(dioProvider).post<Object?>(
      '/companion/message',
      data: {'text': text},
    );
    final body = unwrapEnvelope(response.data) as Map;
    return (
      reply: (body['reply'] as String?) ?? '',
      replyKind: (body['reply_kind'] as String?) ?? 'fallback_template',
      suggestedAction: body['suggested_action'] as String?,
      resources: [
        for (final r in (body['resources'] as List? ?? const []))
          CrisisResource.fromJson(r as Map),
      ],
    );
  } catch (_) {
    return null;
  }
}

/// Conversación en memoria de esta sesión de app: arranca con el historial
/// del servidor y crece con cada turno.
final companionThreadProvider =
    NotifierProvider<CompanionThread, List<CompanionTurn>>(
  CompanionThread.new,
);

class CompanionThread extends Notifier<List<CompanionTurn>> {
  @override
  List<CompanionTurn> build() => const [];

  void seed(List<CompanionTurn> turns) {
    if (state.isEmpty) state = turns;
  }

  void addMine(String text) {
    state = [
      ...state,
      (
        id: 'local-${state.length}',
        role: 'user',
        content: text,
        resources: const <CrisisResource>[],
      ),
    ];
  }

  void addAura(String text, {List<CrisisResource> resources = const []}) {
    state = [
      ...state,
      (
        id: 'local-${state.length}',
        role: 'assistant',
        content: text,
        resources: resources,
      ),
    ];
  }

  bool isMine(CompanionTurn turn) => _isMine(turn.role);
}
