import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../shared/domain/enums.dart';
import '../models/check_in_result_model.dart';

/// Fuente remota del check-in: habla HTTP y desenvuelve el envelope.
class CheckInRemoteDataSource {
  CheckInRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CheckInResultModel> submit(EmotionalState state) async {
    final response = await _dio.post<Object?>(
      '/check-in',
      data: {'emotional_state': state.wireValue},
    );
    final body = unwrapEnvelope(response.data) as Map;
    return CheckInResultModel.fromJson(body);
  }

  Future<CheckInResultModel> todayResult() async {
    final response = await _dio.get<Object?>('/recommendation/today');
    final body = unwrapEnvelope(response.data) as Map;
    return CheckInResultModel.fromJson(body);
  }

  /// Sustituye UN hábito de hoy (`PATCH /recommendation/today`). El servidor
  /// valida energía, balance de áreas y presupuesto de tiempo.
  Future<CheckInResultModel> swapHabit({
    required int slot,
    required String habitId,
  }) async {
    final response = await _dio.patch<Object?>(
      '/recommendation/today',
      data: {'slot': slot, 'habit_id': habitId},
    );
    final body = unwrapEnvelope(response.data) as Map;
    return CheckInResultModel.fromJson(body);
  }
}
