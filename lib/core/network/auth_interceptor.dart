import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_envelope.dart';

/// Interceptor de autenticación.
///
/// Responsabilidades:
/// 1. Adjuntar `Authorization: Bearer <access>` a cada petición.
/// 2. Ante un 401, refrescar el par de tokens (ROTADO) y reintentar UNA vez.
/// 3. Si el refresh falla, limpiar la sesión (fuerza logout).
///
/// Extiende [QueuedInterceptor] para SERIALIZAR los 401 concurrentes: si varias
/// peticiones caen a la vez, solo la primera refresca; las siguientes detectan
/// que el access ya cambió y reintentan con el nuevo, sin refrescar de más.
class AuthInterceptor extends QueuedInterceptor {
  /// [refreshClient] es un Dio SIN interceptores: refresca y reintenta sin recursión.
  AuthInterceptor(this._storage, this._refreshClient);

  final TokenStorage _storage;
  final Dio _refreshClient;

  static const _retriedFlag = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await _storage.readAccess();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final isRefreshCall = request.path.contains('/auth/refresh');
    final alreadyRetried = request.extra[_retriedFlag] == true;

    if (!isUnauthorized || isRefreshCall || alreadyRetried) {
      return handler.next(err);
    }

    // Caso cola: otra petición ya refrescó mientras esta esperaba. Si el access
    // actual difiere del que usó la petición fallida, reintenta directo.
    final currentAccess = await _storage.readAccess();
    final usedAuth = request.headers['Authorization'];
    if (currentAccess != null &&
        currentAccess.isNotEmpty &&
        'Bearer $currentAccess' != usedAuth) {
      return _retry(request, currentAccess, handler, err);
    }

    final refresh = await _storage.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      return handler.next(err);
    }

    try {
      final response = await _refreshClient.post<Object?>(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = unwrapEnvelope(response.data) as Map;
      final newAccess = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      await _storage.saveTokens(access: newAccess, refresh: newRefresh);
      return _retry(request, newAccess, handler, err);
    } catch (_) {
      // Refresh inválido o reuse-detection: la sesión murió.
      await _storage.clear();
      return handler.next(err);
    }
  }

  /// Reintenta la petición original una sola vez con el access vigente.
  Future<void> _retry(
    RequestOptions request,
    String access,
    ErrorInterceptorHandler handler,
    DioException original,
  ) async {
    request.extra[_retriedFlag] = true;
    request.headers['Authorization'] = 'Bearer $access';
    try {
      final clone = await _refreshClient.fetch<Object?>(request);
      handler.resolve(clone);
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(original);
    }
  }
}
