import '../../domain/entities/auth_tokens.dart';

/// DTO de [AuthTokens]: conoce el JSON del contrato (`AuthTokens` en openapi.yaml).
class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({
    required super.accessToken,
    required super.refreshToken,
  });

  /// Construye desde el contenido de `data` ya desenvuelto del envelope.
  factory AuthTokensModel.fromJson(Map<dynamic, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}
