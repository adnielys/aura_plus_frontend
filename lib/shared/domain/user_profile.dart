import 'enums.dart';

/// Perfil de la usuaria. Entidad pura del dominio (sin JSON, sin Dio, sin
/// Flutter). Es transversal: la crea el onboarding y la consumen profile/home.
///
/// `initialFeeling` no forma parte del perfil de salida del contrato: es un dato
/// del momento del onboarding, no un atributo permanente.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.childrenCount,
    required this.childrenAges,
    required this.mainPain,
    required this.dailyTimeSlot,
    required this.preferredMoment,
    required this.onboardingCompleted,
    this.age,
  });

  final String id;
  final String name;

  /// Demográfico opcional (puede no haberse respondido nunca).
  final int? age;
  final int childrenCount;
  final List<ChildAge> childrenAges;
  final MainPain? mainPain;
  final TimeSlot dailyTimeSlot;
  final PreferredMoment preferredMoment;
  final bool onboardingCompleted;
}
