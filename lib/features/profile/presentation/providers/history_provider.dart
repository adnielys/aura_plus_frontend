import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/utils/dates.dart';
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

/// Historia total (Q3): secciones para la lista — "THIS WEEK" (últimos 7 días)
/// y después una por mes ("JULY", "MAY 2025"). Pura y testeable; asume la
/// entrada ya ordenada descendente (así la envía el servidor).
List<({String label, List<HistoryDay> days})> groupHistoryMonths(
  List<HistoryDay> days,
  DateTime today,
) {
  final (thisWeek: thisWeek, earlier: earlier) = groupHistory(days, today);
  final sections = <({String label, List<HistoryDay> days})>[
    if (thisWeek.isNotEmpty) (label: 'THIS WEEK', days: thisWeek),
  ];
  for (final day in earlier) {
    final label = monthLabel(day.date, today).toUpperCase();
    if (sections.isEmpty || sections.last.label != label) {
      sections.add((label: label, days: []));
    }
    sections.last.days.add(day);
  }
  return sections;
}

/// Página de días con presencia ANTERIORES a [before] (cursor exclusivo),
/// sin tope de antigüedad. Lista más corta que [limit] = no hay más atrás.
const historyPageSize = 30;

Future<List<HistoryDay>> fetchHistoryPage(
  Dio dio, {
  required DateTime before,
  int limit = historyPageSize,
}) async {
  final response = await dio.get<Object?>(
    '/session/history',
    queryParameters: {
      'before':
          '${before.year.toString().padLeft(4, '0')}-${before.month.toString().padLeft(2, '0')}-${before.day.toString().padLeft(2, '0')}',
      'limit': limit,
    },
  );
  final body = unwrapEnvelope(response.data);
  return [
    for (final item in (body as List? ?? const [])) _dayFromJson(item as Map),
  ];
}

HistoryDay _dayFromJson(Map item) => (
      date: DateTime.parse(item['date'] as String),
      starsEarned: (item['stars_earned'] as int?) ?? 0,
      state: item['emotional_state'] == null
          ? null
          : EmotionalState.fromWire(item['emotional_state'] as String),
      hadSession: (item['had_session'] as bool?) ?? false,
      gesturesCount: (item['gestures_count'] as int?) ?? 0,
    );

/// Primera página de la historia total: días con presencia hasta hoy,
/// descendente, SIN el tope viejo de 28 días (Q3). El servidor SOLO envía
/// días con check-in o cierre: el silencio no aparece ni se cuenta
/// (GUARD_TONE_02/03). Las páginas siguientes las pide la pantalla con
/// [fetchHistoryPage] al acercarse al final del scroll.
final historyProvider = FutureProvider<List<HistoryDay>>((ref) async {
  final dio = ref.watch(dioProvider);
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return fetchHistoryPage(dio, before: tomorrow);
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
