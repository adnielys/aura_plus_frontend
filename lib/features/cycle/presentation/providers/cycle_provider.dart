import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';

/// Estación interior (contrato `CycleView.season`). `estimated` = solo "may"
/// (GUARD_MENS_04): la UI jamás la presenta como hecho.
typedef CycleSeasonInfo = ({String key, bool estimated});

/// Vista de Mi ciclo (`GET /cycle`). `null` = nunca configuró (invitación C1).
typedef CycleView = ({
  String mode,
  String regularity,
  bool showChip,
  DateTime? lastPeriodStart,
  CycleSeasonInfo? season,
});

CycleView _viewFromJson(Map body) {
  final season = body['season'] as Map?;
  final last = body['last_period_start'] as String?;
  return (
    mode: (body['mode'] as String?) ?? 'off',
    regularity: (body['regularity'] as String?) ?? 'not_sure',
    showChip: (body['show_chip'] as bool?) ?? true,
    lastPeriodStart: last == null ? null : DateTime.tryParse(last),
    season: season == null
        ? null
        : (
            key: (season['key'] as String?) ?? '',
            estimated: (season['estimated'] as bool?) ?? true,
          ),
  );
}

/// Mi ciclo. El dato SOLO viaja por aquí: jamás en push ni compartido
/// (GUARD_MENS_01/02 en el servidor). Error de red -> null silencioso en el
/// chip del Home; el tab sí muestra reintento vía su propio estado.
final cycleProvider = FutureProvider<CycleView?>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/cycle');
  final body = unwrapEnvelope(response.data);
  if (body == null) return null;
  return _viewFromJson(body as Map);
});

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Opt-in / reconfiguración (POST /cycle). El consentimiento lo sella el servidor.
Future<void> setupCycle(
  WidgetRef ref, {
  required String mode,
  String regularity = 'not_sure',
  DateTime? lastPeriodStart,
}) async {
  await ref.read(dioProvider).post<Object?>('/cycle', data: {
    'mode': mode,
    'regularity': regularity,
    if (lastPeriodStart != null) 'last_period_start': _isoDate(lastPeriodStart),
  });
  ref.invalidate(cycleProvider);
}

/// Ajustes (C4): cambiable cuando quiera, sin preguntas.
Future<void> updateCycle(
  WidgetRef ref, {
  String? mode,
  String? regularity,
  bool? showChip,
}) async {
  await ref.read(dioProvider).patch<Object?>('/cycle', data: {
    'mode': ?mode,
    'regularity': ?regularity,
    'show_chip': ?showChip,
  });
  ref.invalidate(cycleProvider);
}

/// "My period started today" — el único registro, la única certeza.
Future<void> logPeriodStart(WidgetRef ref, {DateTime? date}) async {
  await ref.read(dioProvider).post<Object?>(
    '/cycle/period-start',
    data: {if (date != null) 'date': _isoDate(date)},
  );
  ref.invalidate(cycleProvider);
}

/// "Erase all my cycle data" — borrado REAL e inmediato (GUARD_MENS_03).
Future<void> deleteCycleData(WidgetRef ref) async {
  await ref.read(dioProvider).delete<Object?>('/cycle');
  ref.invalidate(cycleProvider);
}
