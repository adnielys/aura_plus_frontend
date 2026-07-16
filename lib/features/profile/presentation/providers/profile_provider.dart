import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/data/models/user_profile_model.dart';
import '../../../../shared/domain/user_profile.dart';

/// Perfil de la usuaria (`GET /profile`).
final profileProvider = FutureProvider<UserProfile>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/profile');
  final body = unwrapEnvelope(response.data) as Map;
  return UserProfileModel.fromJson(body);
});

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
