import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../data/datasources/onboarding_remote_data_source.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_data.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Número de pasos del onboarding: la frase continua se construye PROGRESIVA
/// (maquetado `aura_preview`: cada entrada es un paso con su "Continuar" y la
/// frase va apareciendo línea a línea) — nombre → edad → peques → sentimiento —
/// y después dolor → tiempo → momento.
const int kOnboardingSteps = 7;

/// Estado inmutable del flujo de onboarding: el paso actual + las respuestas en
/// progreso. Los campos opcionales pueden quedar nulos; los tres requeridos por
/// el contrato (nombre, tiempo, momento) se validan antes de enviar.
class OnboardingState {
  const OnboardingState({
    this.stepIndex = 0,
    this.name = '',
    this.age,
    this.feelings = const [],
    this.childrenCount,
    this.childrenAges = const [],
    this.mainPain,
    this.dailyTimeSlot,
    this.preferredMoment,
    this.isSubmitting = false,
    this.completed = false,
    this.errorMessage,
  });

  final int stepIndex;
  final String name;
  final int? age;

  /// Sentimientos de hoy (multi-selección, como el maquetado).
  final List<Feeling> feelings;
  final int? childrenCount;
  final List<ChildAge> childrenAges;
  final MainPain? mainPain;
  final TimeSlot? dailyTimeSlot;
  final PreferredMoment? preferredMoment;
  final bool isSubmitting;
  final bool completed;
  final String? errorMessage;

  bool get isLastStep => stepIndex == kOnboardingSteps - 1;

  /// ¿Puede avanzar desde el paso actual? Nombre y sentimiento son requeridos;
  /// edad y peques son opcionales (saltarlos siempre está permitido); los
  /// pasos finales piden su respuesta.
  bool get canContinue {
    return switch (stepIndex) {
      0 => name.trim().isNotEmpty,
      1 => true, // edad: demográfico opcional
      2 => true, // peques: opcional (0 es una respuesta válida)
      3 => feelings.isNotEmpty,
      4 => mainPain != null,
      5 => dailyTimeSlot != null,
      6 => preferredMoment != null,
      _ => false,
    };
  }

  OnboardingState copyWith({
    int? stepIndex,
    String? name,
    int? age,
    List<Feeling>? feelings,
    int? childrenCount,
    List<ChildAge>? childrenAges,
    MainPain? mainPain,
    TimeSlot? dailyTimeSlot,
    PreferredMoment? preferredMoment,
    bool? isSubmitting,
    bool? completed,
    String? errorMessage,
  }) {
    return OnboardingState(
      stepIndex: stepIndex ?? this.stepIndex,
      name: name ?? this.name,
      age: age ?? this.age,
      feelings: feelings ?? this.feelings,
      childrenCount: childrenCount ?? this.childrenCount,
      childrenAges: childrenAges ?? this.childrenAges,
      mainPain: mainPain ?? this.mainPain,
      dailyTimeSlot: dailyTimeSlot ?? this.dailyTimeSlot,
      preferredMoment: preferredMoment ?? this.preferredMoment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      completed: completed ?? this.completed,
      errorMessage: errorMessage,
    );
  }
}

/// Inyección del repositorio de onboarding (red → datasource → repo).
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(
    OnboardingRemoteDataSource(ref.watch(dioProvider)),
  );
});

/// Controlador del flujo. La UI llama a los setters por paso y observa el estado.
final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);

class OnboardingController extends Notifier<OnboardingState> {
  OnboardingRepository get _repository => ref.read(onboardingRepositoryProvider);

  @override
  OnboardingState build() => const OnboardingState();

  void setName(String value) => state = state.copyWith(name: value);

  /// Edad demográfica opcional. La UI la acota a un rango razonable; el backend
  /// aplica además su validación laxa (fuera de rango persiste null).
  void setAge(int value) => state = state.copyWith(age: value);

  /// Marca/desmarca un sentimiento (multi-selección, como el maquetado).
  void toggleFeeling(Feeling value) {
    final next = [...state.feelings];
    if (!next.remove(value)) next.add(value);
    state = state.copyWith(feelings: next);
  }

  void setChildren({required int count, List<ChildAge> ages = const []}) =>
      state = state.copyWith(childrenCount: count, childrenAges: ages);

  void setMainPain(MainPain value) => state = state.copyWith(mainPain: value);

  void setTimeSlot(TimeSlot value) => state = state.copyWith(dailyTimeSlot: value);

  void setMoment(PreferredMoment value) =>
      state = state.copyWith(preferredMoment: value);

  /// Avanza un paso (sin pasarse del último).
  void next() {
    if (!state.canContinue || state.isLastStep) return;
    state = state.copyWith(stepIndex: state.stepIndex + 1);
  }

  /// Retrocede un paso (sin bajar del primero).
  void back() {
    if (state.stepIndex == 0) return;
    state = state.copyWith(stepIndex: state.stepIndex - 1);
  }

  /// "Cancelar y empezar de nuevo" (maquetado): borra las respuestas y vuelve
  /// al primer paso de la frase.
  void restart() => state = const OnboardingState();

  /// "Tap any word to edit it" (maquetado): salta a un paso ya respondido.
  void goToStep(int index) {
    if (index < 0 || index >= kOnboardingSteps) return;
    state = state.copyWith(stepIndex: index);
  }

  /// Envía el onboarding. Solo construible si los tres requeridos están; la UI
  /// impide llegar aquí incompleta, pero lo reverificamos por seguridad.
  Future<void> submit() async {
    final timeSlot = state.dailyTimeSlot;
    final moment = state.preferredMoment;
    if (state.name.trim().isEmpty || timeSlot == null || moment == null) return;

    state = state.copyWith(isSubmitting: true);
    try {
      await _repository.complete(
        OnboardingData(
          name: state.name.trim(),
          dailyTimeSlot: timeSlot,
          preferredMoment: moment,
          age: state.age,
          feelings: state.feelings,
          childrenCount: state.childrenCount,
          childrenAges: state.childrenAges,
          mainPain: state.mainPain,
        ),
      );
      state = state.copyWith(isSubmitting: false, completed: true);
      // El router redirige a Home al marcar el onboarding como completo.
      ref.read(onboardingStatusProvider.notifier).markComplete();
    } on Failure catch (failure) {
      state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
    }
  }
}

/// Estado de onboarding que gobierna el ruteo (junto con [AuthStatus]).
/// `unknown` mantiene a la usuaria en el splash hasta resolver el `GET /status`.
enum OnboardingStatus { unknown, incomplete, complete }

/// Fuente de verdad del ruteo por onboarding. La consulta el splash tras
/// autenticar; el flujo la marca `complete` al terminar; el logout la resetea.
final onboardingStatusProvider =
    NotifierProvider<OnboardingStatusController, OnboardingStatus>(
  OnboardingStatusController.new,
);

class OnboardingStatusController extends Notifier<OnboardingStatus> {
  @override
  OnboardingStatus build() => OnboardingStatus.unknown;

  /// Consulta `GET /onboarding/status`. Ante fallo deja `unknown` para que el
  /// splash muestre reintento (nunca asumir incompleto: reharía el onboarding).
  Future<void> refresh() async {
    try {
      final completed = await ref.read(onboardingRepositoryProvider).isCompleted();
      state = completed ? OnboardingStatus.complete : OnboardingStatus.incomplete;
    } on Failure {
      state = OnboardingStatus.unknown;
    }
  }

  void markComplete() => state = OnboardingStatus.complete;

  void reset() => state = OnboardingStatus.unknown;

  /// Reinicia el onboarding: `DELETE /onboarding` en el servidor (el cielo se
  /// conserva), limpia el formulario y fuerza el ruteo de vuelta al flujo.
  /// Propaga [Failure] para que la UI muestre el error.
  Future<void> restartOnboarding() async {
    await ref.read(onboardingRepositoryProvider).restart();
    ref.read(onboardingControllerProvider.notifier).restart();
    state = OnboardingStatus.incomplete;
  }
}
