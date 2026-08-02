import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/notifications/local_daily_notifications.dart';
import '../../../../shared/data/models/user_profile_model.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/domain/user_profile.dart';

/// Perfil de la usuaria (`GET /profile`).
final profileProvider = FutureProvider<UserProfile>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/profile');
  final body = unwrapEnvelope(response.data) as Map;
  return UserProfileModel.fromJson(body);
});

/// Sincroniza la timezone del DISPOSITIVO con el servidor (una vez por
/// arranque, tras autenticar). El backend calcula "su hoy" con ella: sin esto,
/// pasada la medianoche UTC el check-in de la tarde "desaparecería" y el
/// cierre fallaría con checkin_required. Nunca bloquea la app si falla.
Future<void> syncDeviceTimezone(WidgetRef ref) async {
  try {
    final timezone = await FlutterTimezone.getLocalTimezone();
    await ref.read(dioProvider).patch<Object?>(
      '/notification-settings',
      data: {'timezone': timezone.identifier},
    );
  } catch (_) {
    // Sin red o sin plugin: se reintenta en el próximo arranque.
  }
}

/// Marca de que el idioma del teléfono ya se propuso una vez.
const _deviceLangSyncedKey = 'device_language_synced';

/// Propone el idioma del DISPOSITIVO al servidor — UNA SOLA VEZ por
/// instalación, a diferencia de la timezone.
///
/// La timezone es un HECHO y se sincroniza en cada arranque; el idioma es una
/// PREFERENCIA. Si lo mandáramos siempre, una madre en Berlín que eligió
/// español volvería al alemán cada vez que abre la app: eso no es acompañar,
/// es corregirla. Se propone al principio y después manda ella.
///
/// Hoy decide los textos que vienen del servidor (la conversación con Aura y
/// el catálogo emocional). La interfaz sigue en inglés hasta que esté
/// traducida. Nunca bloquea el arranque.
Future<void> syncDeviceLanguage(WidgetRef ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_deviceLangSyncedKey) ?? false) return;

    final locale = PlatformDispatcher.instance.locale.languageCode;
    await ref.read(dioProvider).patch<Object?>(
      '/profile',
      data: {'lang': AppLanguage.fromLocale(locale).wireValue},
    );
    await prefs.setBool(_deviceLangSyncedKey, true);
    ref.invalidate(profileProvider);
  } catch (_) {
    // Sin red todavía: se reintenta en el próximo arranque (la marca solo se
    // escribe cuando el servidor lo aceptó).
  }
}

/// En qué idioma le habla Aura: un tap = PATCH /profile. Su elección manda
/// desde este momento sobre el idioma del teléfono.
Future<void> updateLanguage(WidgetRef ref, AppLanguage lang) async {
  await ref.read(dioProvider).patch<Object?>(
    '/profile',
    data: {'lang': lang.wireValue},
  );
  // Que no se lo vuelva a proponer el dispositivo en el próximo arranque.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_deviceLangSyncedKey, true);
  ref.invalidate(profileProvider);
}

/// "Lo que más te pesa ahora" (Mis áreas M2): un tap = PATCH /profile.
/// Sin diálogo, sin preguntas, sin culpa — y no cambia estrellas ni exige nada.
Future<void> updateMainPain(WidgetRef ref, MainPain pain) async {
  await ref.read(dioProvider).patch<Object?>(
    '/profile',
    data: {'main_pain': pain.wireValue},
  );
  ref.invalidate(profileProvider);
}

/// Cómo le habla Aura (Q4): un tap = PATCH /profile. Cambiable cuando quiera,
/// sin preguntas — solo sesga la rotación del catálogo en el servidor.
Future<void> updateMessageStyle(WidgetRef ref, MessageStyle style) async {
  await ref.read(dioProvider).patch<Object?>(
    '/profile',
    data: {'message_style': style.wireValue},
  );
  ref.invalidate(profileProvider);
}

/// Actualiza los ajustes (`PATCH /notification-settings`) y refresca
/// [notificationSettingsProvider]. `preferredTime` en formato 'HH:mm'.
Future<void> updateNotificationSettings(
  WidgetRef ref, {
  bool? isEnabled,
  String? preferredTime,
}) async {
  final dio = ref.read(dioProvider);
  await dio.patch<Object?>('/notification-settings', data: {
    'is_enabled': ?isEnabled,
    if (preferredTime != null) 'preferred_time': '$preferredTime:00',
  });
  ref.invalidate(notificationSettingsProvider);
  // La diaria es LOCAL (sin Google): reprogramar con los valores frescos.
  try {
    final settings = await ref.read(notificationSettingsProvider.future);
    await scheduleDailyNotifications(
      enabled: settings.isEnabled,
      preferredTime: settings.preferredTime,
    );
  } catch (_) {
    // Sin red o sin permiso: el próximo arranque reprograma.
  }
}

/// Ajustes de notificación (`GET /notification-settings`): hora real de la
/// única notificación diaria (derivada del momento elegido en onboarding).
final notificationSettingsProvider =
    FutureProvider<({bool isEnabled, String preferredTime})>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/notification-settings');
  final body = unwrapEnvelope(response.data) as Map;
  final time = (body['preferred_time'] as String?) ?? '';
  return (
    isEnabled: (body['is_enabled'] as bool?) ?? true,
    // 'HH:mm:ss' -> 'HH:mm'
    preferredTime: time.length >= 5 ? time.substring(0, 5) : time,
  );
});
