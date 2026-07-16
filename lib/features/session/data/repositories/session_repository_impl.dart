import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_envelope.dart';
import '../../../../shared/domain/enums.dart';
import '../../domain/entities/session_result.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_data_source.dart';

/// Implementación de [SessionRepository]: traduce transporte/contrato a Failure.
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._remote);

  final SessionRemoteDataSource _remote;

  @override
  Future<SessionResult> close({
    required HabitResult habit1Result,
    HabitResult? habit2Result,
    String? reflection,
  }) async {
    try {
      return await _remote.close(
        habit1Result: habit1Result,
        habit2Result: habit2Result,
        reflection: reflection,
      );
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
