import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';

bool _initialized = false;

/// Registra el dispositivo para LA notificación diaria (GUARD_NOTIF_03:
/// una sola al día, a su hora — el servidor manda).
///
/// Tolerante por diseño: sin google-services.json, Firebase no inicializa y
/// esto es un no-op silencioso — la app jamás se bloquea por push. Con el
/// archivo en android/app/, se activa solo: pide el permiso (Android 13+),
/// sube el token (PATCH /notification-settings) y lo mantiene fresco.
Future<void> registerPushToken(WidgetRef ref) async {
  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;

    // Android 13+ requiere permiso explícito; en versiones previas es no-op.
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // su decisión; no se insiste (el silencio nunca castiga)
    }

    final dio = ref.read(dioProvider);
    final token = await messaging.getToken();
    if (token != null) {
      await _upload(dio, token);
    }

    if (!_initialized) {
      _initialized = true;
      // El token puede rotar (reinstalación, restauración): mantenerlo fresco.
      messaging.onTokenRefresh.listen((fresh) => _upload(dio, fresh));
    }
  } catch (_) {
    // Sin configuración de Firebase o sin red: se reintenta en el próximo
    // arranque. Nunca bloquea la app.
  }
}

Future<void> _upload(Dio dio, String token) async {
  try {
    await dio.patch<Object?>(
      '/notification-settings',
      data: {'fcm_token': token},
    );
  } catch (_) {
    // Sin red: el próximo arranque lo vuelve a subir.
  }
}
