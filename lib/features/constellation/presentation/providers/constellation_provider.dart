import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/data/models/constellation_model.dart';
import '../../../../shared/domain/constellation.dart';

/// Constelación actual (`GET /constellation/current`). `null` = todavía no hay
/// (p. ej. justo tras registrarse). La llamada dispara el rollover perezoso en
/// el servidor.
final currentConstellationProvider =
    FutureProvider<Constellation?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get<Object?>('/constellation/current');
    final body = unwrapEnvelope(response.data) as Map;
    return ConstellationModel.fromJson(body);
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  } on ApiException catch (e) {
    if (e.httpStatus == 404) return null;
    rethrow;
  }
});

/// Todas las constelaciones (`GET /constellation/all`, desc por ciclo) para
/// la galaxia: el cielo guarda lo construido, ciclo a ciclo.
final allConstellationsProvider =
    FutureProvider<List<Constellation>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/constellation/all');
  final body = unwrapEnvelope(response.data);
  return [
    for (final item in (body as List? ?? const []))
      ConstellationModel.fromJson(item as Map),
  ];
});
