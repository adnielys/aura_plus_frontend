import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';

/// Áreas con al menos un gesto REALIZADO (done/partial) en el ciclo actual
/// (`GET /areas/presence`). Presencia, no eficiencia: solo acumula y no se
/// apaga hasta el ciclo nuevo. El Home las pinta ENCENDIDAS; las demás quedan
/// en perla, nunca "vacías" (mockup_balance_areas aprobado).
final areasPresenceProvider = FutureProvider<Set<HabitArea>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/areas/presence');
  final body = unwrapEnvelope(response.data) as Map;
  return {
    for (final wire in (body['lit_areas'] as List? ?? const []))
      HabitArea.fromWire(wire as String),
  };
});
