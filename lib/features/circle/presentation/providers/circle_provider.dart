import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';

/// Una persona del círculo. Antivigilancia inversa: el contrato jamás trae
/// "lo abrió/visto" — espejo de lo compartido sí, radar de quién mira no.
typedef CircleMember = ({String id, String email, String status});

/// El resumen semanal agregado (SharedView) — el ESPEJO exacto de lo que ven.
typedef SharedView = ({
  String period,
  bool quiet,
  String? presence,
  String? mostPresentArea,
  String note,
});

typedef CircleView = ({
  bool paused,
  int spotsLeft,
  List<CircleMember> members,
  SharedView sharedView,
});

CircleView _fromJson(Map body) {
  final view = body['shared_view'] as Map? ?? const {};
  return (
    paused: (body['paused'] as bool?) ?? false,
    spotsLeft: (body['spots_left'] as int?) ?? 3,
    members: [
      for (final m in (body['members'] as List? ?? const []))
        (
          id: ((m as Map)['id'] as String?) ?? '',
          email: (m['email'] as String?) ?? '',
          status: (m['status'] as String?) ?? 'invited',
        ),
    ],
    sharedView: (
      period: (view['period'] as String?) ?? '',
      quiet: (view['quiet'] as bool?) ?? true,
      presence: view['presence'] as String?,
      mostPresentArea: view['most_present_area'] as String?,
      note: (view['note'] as String?) ?? '',
    ),
  );
}

/// Mi círculo (`GET /circle`). Siempre existe (vacío si nunca invitó).
final circleProvider = FutureProvider<CircleView>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/circle');
  return _fromJson(unwrapEnvelope(response.data) as Map);
});

Future<void> inviteCircleMember(WidgetRef ref, String email) async {
  await ref.read(dioProvider).post<Object?>(
    '/circle/members',
    data: {'email': email},
  );
  ref.invalidate(circleProvider);
}

/// Revocación silenciosa: el enlace muere YA, sin avisar a nadie.
Future<void> revokeCircleMember(WidgetRef ref, String memberId) async {
  await ref.read(dioProvider).delete<Object?>('/circle/members/$memberId');
  ref.invalidate(circleProvider);
}

/// D3: pausa de un toque del círculo entero, sin borrar a nadie.
Future<void> setCirclePaused(WidgetRef ref, bool paused) async {
  await ref.read(dioProvider).patch<Object?>(
    '/circle',
    data: {'paused': paused},
  );
  ref.invalidate(circleProvider);
}
