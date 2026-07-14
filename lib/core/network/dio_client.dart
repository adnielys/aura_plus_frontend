import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

const _timeout = Duration(seconds: 15);

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: _timeout,
      receiveTimeout: _timeout,
      sendTimeout: _timeout,
      contentType: Headers.jsonContentType,
      // Solo las respuestas <400 se consideran válidas; 4xx/5xx → DioException,
      // que la capa `data` traduce a Failure. El 401 dispara el AuthInterceptor.
      validateStatus: (status) => status != null && status < 400,
    );

/// Dio plano para refrescar tokens y reintentar, sin interceptores (evita la
/// recursión del refresh).
final _refreshDioProvider = Provider<Dio>((ref) => Dio(_baseOptions()));

/// Cliente HTTP principal de la app: base URL por plataforma + AuthInterceptor.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      ref.watch(tokenStorageProvider),
      ref.watch(_refreshDioProvider),
    ),
  );
  return dio;
});
