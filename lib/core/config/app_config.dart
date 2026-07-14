import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración de entorno de la app.
///
/// La base URL depende de la plataforma porque el backend corre en el host
/// (Docker en el PC), no dentro del emulador. Ver reconciliación #9 del handoff:
/// - Android emulador: 10.0.2.2 mapea al localhost del PC.
/// - iOS simulador / web: localhost del PC.
/// - Dispositivo físico: IP de la LAN (sobrescribir con --dart-define).
abstract final class AppConfig {
  const AppConfig._();

  /// Permite override en build/run: `--dart-define=API_BASE_URL=http://192.168.x.x:8000`.
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  /// Versión de política de privacidad vigente (para ConsentGrant, fuera del MVP frontend).
  static const String privacyPolicyVersion = '1.0';
}
