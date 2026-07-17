import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_envelope.dart';
import '../../../../shared/domain/enums.dart';
import '../../domain/entities/check_in_result.dart';
import '../../domain/repositories/check_in_repository.dart';
import '../datasources/check_in_remote_data_source.dart';

/// Implementación de [CheckInRepository]: traduce transporte/contrato a Failure.
class CheckInRepositoryImpl implements CheckInRepository {
  CheckInRepositoryImpl(this._remote);

  final CheckInRemoteDataSource _remote;

  @override
  Future<CheckInResult> submit(EmotionalState state) =>
      _guard(() => _remote.submit(state));

  @override
  Future<CheckInResult> swapHabit({required int slot, required String habitId}) =>
      _guard(() => _remote.swapHabit(slot: slot, habitId: habitId));

  @override
  Future<CheckInResult?> today() async {
    try {
      return await _guard(_remote.todayResult);
    } on ApiFailure catch (failure) {
      // Sin check-in hoy: flujo normal, no un error.
      if (failure.httpStatus == 404) return null;
      rethrow;
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (e) {
      throw ApiFailure(code: e.code, message: e.message, httpStatus: e.httpStatus);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Failure _mapDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiFailure(
        code: (error['code'] as String?) ?? 'unknown',
        message: (error['message'] as String?) ?? 'Error desconocido.',
        httpStatus:
            (error['http_status'] as int?) ?? e.response?.statusCode ?? 0,
      );
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        const NetworkFailure(),
      _ => const UnknownFailure(),
    };
  }
}
