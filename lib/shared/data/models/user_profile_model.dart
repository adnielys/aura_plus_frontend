import '../../domain/enums.dart';
import '../../domain/user_profile.dart';

/// DTO de [UserProfile]: conoce el JSON del contrato (`UserProfile` en
/// openapi.yaml). Mapea los enums por su `wireValue`, nunca por `.name`.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.name,
    required super.childrenCount,
    required super.childrenAges,
    required super.mainPain,
    required super.dailyTimeSlot,
    required super.preferredMoment,
    required super.onboardingCompleted,
    super.age,
  });

  /// Construye desde el contenido de `data` ya desenvuelto del envelope.
  factory UserProfileModel.fromJson(Map<dynamic, dynamic> json) {
    final rawAges = (json['children_ages'] as List?) ?? const [];
    final mainPain = json['main_pain'] as String?;

    return UserProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      childrenCount: (json['children_count'] as int?) ?? 0,
      childrenAges: [
        for (final age in rawAges) ?ChildAge.tryFromWire(age as String),
      ],
      mainPain: mainPain == null ? null : MainPain.fromWire(mainPain),
      dailyTimeSlot: TimeSlot.fromWire(json['daily_time_slot'] as String),
      preferredMoment:
          PreferredMoment.fromWire(json['preferred_moment'] as String),
      onboardingCompleted: (json['onboarding_completed'] as bool?) ?? true,
    );
  }
}
