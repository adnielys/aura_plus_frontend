import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../models/auth_tokens_model.dart';

/// Fuente remota de auth: habla HTTP con el backend y desenvuelve el envelope.
/// No conoce TokenStorage ni Failures (eso es del repositorio).
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthTokensModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Object?>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseTokens(response.data);
  }

  Future<AuthTokensModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _dio.post<Object?>(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );
    return _parseTokens(response.data);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post<Object?>(
      '/auth/logout',
      data: {'refresh_token': refreshToken},
    );
  }

  AuthTokensModel _parseTokens(Object? body) {
    final data = unwrapEnvelope(body) as Map;
    return AuthTokensModel.fromJson(data);
  }
}
