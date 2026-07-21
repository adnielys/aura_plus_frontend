import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

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

/// "Lo que más te pesa ahora" (Mis áreas M2): un tap = PATCH /profile.
/// Sin diálogo, sin preguntas, sin culpa — y no cambia estrellas ni exige nada.
Future<void> updateMainPain(WidgetRef ref, MainPain pain) async {
  await ref.read(dioProvider).patch<Object?>(
    '/profile',
    data: {'main_pain': pain.wireValue},
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
