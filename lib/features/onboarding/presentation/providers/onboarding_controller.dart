import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../data/datasources/onboarding_remote_data_source.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_data.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Número de pasos del onboarding (nombre → sentimiento → hijos → dolor →
/// tiempo → momento).
const int kOnboardingSteps = 6;

/// Estado inmutable del flujo de onboarding: el paso actual + las respuestas en
/// progreso. Los campos opcionales pueden quedar nulos; los tres requeridos por
/// el contrato (nombre, tiempo, momento) se validan antes de enviar.
class OnboardingState {
  const OnboardingState({
    this.stepIndex = 0,
    this.name = '',
    this.initialFeeling,
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
  final EmotionalState? initialFeeling;
  final int? childrenCount;
  final List<ChildAge> childrenAges;
  final MainPain? mainPain;
  final TimeSlot? dailyTimeSlot;
  final PreferredMoment? preferredMoment;
  final bool isSubmitting;
  final bool completed;
  final String? errorMessage;

  bool get isLastStep => stepIndex == kOnboardingSteps - 1;

  /// ¿Puede avanzar desde el paso actual? Cada paso pide una respuesta antes de
  /// continuar; "0 hijos" es una respuesta válida.
  bool get canContinue {
    return switch (stepIndex) {
      0 => name.trim().isNotEmpty,
      1 => initialFeeling != null,
      2 => childrenCount != null,
      3 => mainPain != null,
      4 => dailyTimeSlot != null,
      5 => preferredMoment != null,
      _ => false,
    };
  }

  OnboardingState copyWith({
    int? stepIndex,
    String? name,
    EmotionalState? initialFeeling,
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
      initialFeeling: initialFeeling ?? this.initialFeeling,
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

  void setFeeling(EmotionalState value) =>
      state = state.copyWith(initialFeeling: value);

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
          initialFeeling: state.initialFeeling,
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
}
