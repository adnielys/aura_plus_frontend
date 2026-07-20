import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import 'area_gestures_provider.dart';

/// Un día con presencia (`WeekDay` del contrato, vía `GET /session/history`).
typedef HistoryDay = ({
  DateTime date,
  int starsEarned,
  EmotionalState? state,
  bool hadSession,
  int gesturesCount, // Historia v2: lo construido, jamás lo que faltó
});

/// La memoria completa de un día (`GET /session/day`, Historia v2 · V2).
/// Nada editable: la memoria no se retoca.
typedef HistoryDayDetail = ({
  DateTime date,
  EmotionalState? state,
  int starsEarned,
  List<AreaGesture> gestures,
  String? closingMessage,
  String? reflection,
});

/// Agrupa por cercanía para la lista (V1): los últimos 7 días son "Esta
/// semana"; el resto, "Antes". Pura y testeable.
({List<HistoryDay> thisWeek, List<HistoryDay> earlier}) groupHistory(
  List<HistoryDay> days,
  DateTime today,
) {
  final base = DateTime(today.year, today.month, today.day);
  bool recent(HistoryDay day) {
    final d = DateTime(day.date.year, day.date.month, day.date.day);
    return base.difference(d).inDays < 7;
  }

  return (
    thisWeek: [
      for (final day in days)
        if (recent(day)) day,
    ],
    earlier: [
      for (final day in days)
        if (!recent(day)) day,
    ],
  );
}

/// Días con presencia de los últimos 28, descendente. El servidor SOLO envía
/// días con check-in o cierre: el silencio no aparece ni se cuenta
/// (GUARD_TONE_02/03).
final historyProvider = FutureProvider<List<HistoryDay>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/session/history');
  final body = unwrapEnvelope(response.data);
  return [
    for (final item in (body as List? ?? const []))
      (
        date: DateTime.parse((item as Map)['date'] as String),
        starsEarned: (item['stars_earned'] as int?) ?? 0,
        state: item['emotional_state'] == null
            ? null
            : EmotionalState.fromWire(item['emotional_state'] as String),
        hadSession: (item['had_session'] as bool?) ?? false,
        gesturesCount: (item['gestures_count'] as int?) ?? 0,
      ),
  ];
});

/// La memoria de UN día. Clave: la fecha (solo se navega desde la lista,
/// que ya excluye el silencio).
final historyDayProvider =
    FutureProvider.family<HistoryDayDetail, DateTime>((ref, date) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>(
    '/session/day',
    queryParameters: {
      'date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    },
  );
  final body = unwrapEnvelope(response.data) as Map;
  return (
    date: DateTime.parse(body['date'] as String),
    state: body['emotional_state'] == null
        ? null
        : EmotionalState.fromWire(body['emotional_state'] as String),
    starsEarned: (body['stars_earned'] as int?) ?? 0,
    gestures: [
      for (final item in (body['gestures'] as List? ?? const []))
        areaGestureFromJson(item as Map),
    ],
    closingMessage: body['closing_message'] as String?,
    reflection: body['reflection'] as String?,
  );
});
