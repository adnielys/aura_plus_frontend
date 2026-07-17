import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/data/models/constellation_model.dart';
import '../../../../shared/domain/constellation.dart';

/// Ceremonia de cierre de ciclo pendiente (SPEC_CONTENIDO_EMOCIONAL_V2 §1):
/// la constelación completada + los 3 momentos con el texto YA resuelto.
typedef CycleClosing = ({
  Constellation constellation,
  String intro,
  String meaning,
  String transition,
});

/// `GET /constellation/closing`. `null` = sin ceremonia pendiente (flujo
/// normal) — también ante error de red: la ceremonia jamás compite con el
/// uso diario (spec §1.4).
final cycleClosingProvider = FutureProvider<CycleClosing?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<Object?>('/constellation/closing');
    final body = unwrapEnvelope(response.data) as Map;
    final messages = body['messages'] as Map;
    return (
      constellation:
          ConstellationModel.fromJson(body['constellation'] as Map),
      intro: (messages['intro'] as String?) ?? '',
      meaning: (messages['meaning'] as String?) ?? '',
      transition: (messages['transition'] as String?) ?? '',
    );
  } on ApiException {
    return null; // 404 no_pending_closing u otro: silencio, flujo normal
  } on DioException {
    return null;
  }
});

/// "Ahora no" pospone la ceremonia SOLO durante esta sesión de app (sin ack:
/// el backend la re-ofrece en el próximo arranque).
final cycleClosePostponedProvider = StateProvider<bool>((_) => false);

/// Reflexión opcional de un toque. Errores en silencio: jamás bloquea.
Future<void> sendCycleReflection(
  WidgetRef ref, {
  required String constellationId,
  required String anchor,
}) async {
  try {
    await ref.read(dioProvider).post<Object?>(
      '/constellation/$constellationId/reflection',
      data: {'anchor': anchor},
    );
  } catch (_) {
    // Opcional por contrato: si falla, el cierre sigue igual.
  }
}

/// Marca la ceremonia como vista (idempotente, GUARD_CYCLE_02). Si falla,
/// el backend la re-ofrece en el próximo arranque — reintento silencioso.
Future<void> ackCycleClosing(
  WidgetRef ref, {
  required String constellationId,
}) async {
  try {
    await ref.read(dioProvider).post<Object?>(
      '/constellation/$constellationId/closing-ack',
    );
  } catch (_) {
    // Idempotente: se reintenta solo la próxima vez.
  }
}
