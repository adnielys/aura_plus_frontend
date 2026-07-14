import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_envelope.dart';
import '../../../../shared/domain/user_profile.dart';
import '../../domain/entities/onboarding_data.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_data_source.dart';

/// Implementación de [OnboardingRepository]: orquesta la fuente remota y traduce
/// las excepciones de transporte/contrato a [Failure] tipadas.
class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._remote);

  final OnboardingRemoteDataSource _remote;

  @override
  Future<bool> isCompleted() => _guard(_remote.getStatus);

  @override
  Future<UserProfile> complete(OnboardingData data) =>
      _guard(() => _remote.complete(data));

  /// Ejecuta [action] traduciendo ApiException/DioException a Failure.
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
