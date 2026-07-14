import '../../../../shared/domain/enums.dart';

/// Respuestas completas del onboarding, listas para enviar al backend.
///
/// Entidad pura. Los campos requeridos por el contrato (`name`, `dailyTimeSlot`,
/// `preferredMoment`) son no-nulos aquí: este objeto solo se construye cuando el
/// flujo ya validó esos tres. El resto es opcional.
class OnboardingData {
  const OnboardingData({
    required this.name,
    required this.dailyTimeSlot,
    required this.preferredMoment,
    this.initialFeeling,
    this.childrenCount,
    this.childrenAges = const [],
    this.mainPain,
  });

  final String name;
  final TimeSlot dailyTimeSlot;
  final PreferredMoment preferredMoment;

  final EmotionalState? initialFeeling;
  final int? childrenCount;
  final List<ChildAge> childrenAges;
  final MainPain? mainPain;
}
