import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/api_envelope.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementación de [AuthRepository]: orquesta la fuente remota y el
/// almacenamiento de tokens, y traduce las excepciones a [Failure] tipadas.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  @override
  Future<void> login({required String email, required String password}) {
    return _guard(() async {
      final tokens = await _remote.login(email: email, password: password);
      await _storage.saveTokens(
        access: tokens.accessToken,
        refresh: tokens.refreshToken,
      );
    });
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) {
    return _guard(() async {
      final tokens = await _remote.register(
        email: email,
        password: password,
        name: name,
      );
      await _storage.saveTokens(
        access: tokens.accessToken,
        refresh: tokens.refreshToken,
      );
    });
  }

  @override
  Future<void> logout() async {
    final refresh = await _storage.readRefresh();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _remote.logout(refresh);
      }
    } on DioException {
      // El logout local manda: aunque el backend falle, limpiamos la sesión.
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<bool> hasActiveSession() async {
    final refresh = await _storage.readRefresh();
    return refresh != null && refresh.isNotEmpty;
  }

  /// Ejecuta [action] traduciendo DioException/ApiException a Failure.
  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
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
        httpStatus: (error['http_status'] as int?) ?? e.response?.statusCode ?? 0,
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
