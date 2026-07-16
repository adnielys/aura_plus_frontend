import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../shared/domain/enums.dart';
import '../models/session_result_model.dart';

/// Fuente remota del cierre del día.
class SessionRemoteDataSource {
  SessionRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SessionResultModel> close({
    required HabitResult habit1Result,
    HabitResult? habit2Result,
    String? reflection,
  }) async {
    final response = await _dio.post<Object?>(
      '/session',
      data: {
        'habit_1_result': habit1Result.wireValue,
        'habit_2_result': habit2Result?.wireValue,
        if (reflection != null && reflection.isNotEmpty)
          'reflection': reflection,
      },
    );
    final body = unwrapEnvelope(response.data) as Map;
    return SessionResultModel.fromJson(body);
  }
}
