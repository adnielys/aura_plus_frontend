import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';

/// Un gesto REGISTRADO (`GET /session/gestures`, Mis áreas M3).
///
/// Solo presencia: los tres resultados viajan con idéntica dignidad y los
/// días en silencio no existen aquí (GUARD_TONE_02/03).
typedef AreaGesture = ({
  DateTime date,
  String habitId,
  String title,
  String? icon,
  HabitArea area,
  HabitResult result,
});

AreaGesture areaGestureFromJson(Map<Object?, Object?> json) => (
      date: DateTime.parse(json['date'] as String),
      habitId: json['habit_id'] as String,
      title: json['title'] as String,
      icon: json['icon'] as String?,
      area: HabitArea.fromWire(json['area'] as String),
      result: HabitResult.fromWire(json['result'] as String),
    );

/// Gestos registrados de los últimos 28 días en un área ("Lo que te has
/// regalado en …"). Orden descendente del servidor.
final areaGesturesProvider =
    FutureProvider.family<List<AreaGesture>, HabitArea>((ref, area) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>(
    '/session/gestures',
    queryParameters: {'area': area.wireValue},
  );
  final body = unwrapEnvelope(response.data);
  return [
    for (final item in (body as List? ?? const []))
      areaGestureFromJson(item as Map),
  ];
});
