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
    this.age,
    this.initialFeeling,
    this.feelings = const [],
    this.childrenCount,
    this.childrenAges = const [],
    this.mainPain,
  });

  final String name;
  final TimeSlot dailyTimeSlot;
  final PreferredMoment preferredMoment;

  /// Demográfico opcional (contrato: validación laxa en el backend; saltarlo
  /// siempre está permitido).
  final int? age;
  final EmotionalState? initialFeeling;

  /// Sentimientos de hoy (multi-selección, contrato `initial_feelings`).
  final List<Feeling> feelings;
  final int? childrenCount;
  final List<ChildAge> childrenAges;
  final MainPain? mainPain;
}
