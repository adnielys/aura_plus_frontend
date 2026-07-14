/// Par de tokens JWT. Entidad pura del dominio: sin JSON, sin Dio, sin Flutter.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
