import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';

/// Un día con presencia (`WeekDay` del contrato, vía `GET /session/history`).
typedef HistoryDay = ({
  DateTime date,
  int starsEarned,
  EmotionalState? state,
  bool hadSession,
});

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
      ),
  ];
});
