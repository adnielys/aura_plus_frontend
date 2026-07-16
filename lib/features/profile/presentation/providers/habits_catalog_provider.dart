import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';

/// Un microhábito del catálogo (`GET /habits`, schema `Habit` del contrato).
/// Lista informativa: el motor sigue eligiendo por estado emocional.
typedef CatalogHabit = ({
  String id,
  String title,
  String auraCopy,
  HabitArea area,
  int durationMinutes,
});

/// Catálogo completo de microhábitos activos, ordenado por área en el servidor.
final habitsCatalogProvider = FutureProvider<List<CatalogHabit>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/habits');
  final body = unwrapEnvelope(response.data);
  return [
    for (final item in (body as List? ?? const []))
      (
        id: (item as Map)['id'] as String,
        title: item['title'] as String,
        auraCopy: (item['aura_copy'] as String?) ?? '',
        area: HabitArea.fromWire(item['area'] as String),
        durationMinutes: (item['duration_minutes'] as int?) ?? 0,
      ),
  ];
});
