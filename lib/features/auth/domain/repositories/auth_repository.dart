/// Contrato de autenticación que consume la capa `presentation`.
///
/// Las implementaciones guardan los tokens internamente (TokenStorage) y lanzan
/// [Failure] tipadas; nunca exponen detalles de transporte. Los métodos no
/// devuelven tokens: la sesión es un efecto, no un valor que la UI manipule.
abstract interface class AuthRepository {
  /// Inicia sesión y persiste el par de tokens. Lanza Failure si falla.
  Future<void> login({required String email, required String password});

  /// Registra una cuenta nueva y persiste el par de tokens.
  Future<void> register({
    required String email,
    required String password,
    required String name,
  });

  /// Cierra sesión en el backend (revoca el refresh) y limpia el almacenamiento.
  Future<void> logout();

  /// True si hay un refresh token guardado (sesión candidata a restaurar).
  Future<bool> hasActiveSession();
}
