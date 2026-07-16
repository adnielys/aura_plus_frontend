import 'package:dio/dio.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../shared/data/models/user_profile_model.dart';
import '../../domain/entities/onboarding_data.dart';

/// Fuente remota del onboarding: habla HTTP con el backend y desenvuelve el
/// envelope. No conoce Failures (eso es del repositorio).
class OnboardingRemoteDataSource {
  OnboardingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<bool> getStatus() async {
    final response = await _dio.get<Object?>('/onboarding/status');
    final data = unwrapEnvelope(response.data) as Map;
    return data['completed'] == true;
  }

  Future<UserProfileModel> complete(OnboardingData data) async {
    final response = await _dio.post<Object?>(
      '/onboarding/complete',
      data: _toBody(data),
    );
    final body = unwrapEnvelope(response.data) as Map;
    return UserProfileModel.fromJson(body);
  }

  /// Arma el cuerpo del contrato (`OnboardingData`). Solo incluye los opcionales
  /// cuando tienen valor, y traduce cada enum por su `wireValue`.
  Map<String, Object?> _toBody(OnboardingData data) => {
        'name': data.name,
        if (data.age != null) 'age': data.age,
        if (data.initialFeeling != null)
          'initial_feeling': data.initialFeeling!.wireValue,
        if (data.feelings.isNotEmpty)
          'initial_feelings': [for (final f in data.feelings) f.wireValue],
        if (data.childrenCount != null) 'children_count': data.childrenCount,
        if (data.childrenAges.isNotEmpty)
          'children_ages': [for (final a in data.childrenAges) a.wireValue],
        if (data.mainPain != null) 'main_pain': data.mainPain!.wireValue,
        'daily_time_slot': data.dailyTimeSlot.wireValue,
        'preferred_moment': data.preferredMoment.wireValue,
      };
}
