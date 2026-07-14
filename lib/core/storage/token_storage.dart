import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia segura del par de tokens JWT (access + refresh).
///
/// Usa el keystore/keychain del sistema vía flutter_secure_storage. Es la única
/// pieza que conoce dónde viven los tokens; el resto de la app pasa por aquí.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';

  /// Guarda el par. En refresh rotado (reconciliación #6) SIEMPRE se llama con
  /// el par NUEVO; reusar el viejo dispara reuse-detection en el backend.
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccess() => _storage.read(key: _accessKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  /// Borra la sesión (logout o reuse-detection).
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

/// Provider del almacenamiento de tokens. Se sobrescribe en tests con un fake
/// para no depender del keystore del sistema.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(const FlutterSecureStorage()),
);
