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
}
