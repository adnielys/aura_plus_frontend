import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/datasources/onboarding_remote_data_source.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_data.dart';
import '../../domain/repositories/onboarding_repository.dart';

/// Número de pasos del onboarding: la frase continua se construye PROGRESIVA
/// (maquetado `aura_preview`: cada entrada es un paso con su "Continuar" y la
/// frase va apareciendo línea a línea) — nombre → edad → peques → sentimiento —
/// y después dolor → tiempo → momento.
const int kOnboardingSteps = 7;

/// Pasos de cada bloque: lo personal (nombre, edad, peques, sentimientos) y el
/// día (lo que pesa, tiempo, momento). Cada bloque se cierra en su card.
const List<int> kBlock1Steps = [0, 1, 2, 3];
const List<int> kBlock2Steps = [4, 5, 6];

/// Qué se está viendo. Es una capa ENCIMA de [OnboardingState.stepIndex], que
/// sigue siendo la fuente de verdad de las respuestas: la reestructura en dos
/// cards cambia cómo se recorre el onboarding, no qué se pregunta ni qué se
/// envía.
enum OnboardingView {
  /// Pasos 0–3, uno por pantalla, como siempre.
  block1,

  /// Pasos 4–6.
  block2,

  /// Las dos cards, navegables por swipe: lo que le has contado.
  cards,

  /// Una card abierta a pantalla completa para corregirla.
  editing,

  /// Contrato emocional. Solo se llega con el POST ya resuelto.
  contract,
}

/// Estado inmutable del flujo de onboarding: el paso actual + las respuestas en
/// progreso. Los campos opcionales pueden quedar nulos; los tres requeridos por
/// el contrato (nombre, tiempo, momento) se validan antes de enviar.
class OnboardingState {
  const OnboardingState({
    this.stepIndex = 0,
    this.view = OnboardingView.block1,
    this.editingCard = 1,
    this.folding = false,
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

  /// Qué pantalla se ve. No sustituye a [stepIndex]: convive con él.
  final OnboardingView view;

  /// Card que se está corrigiendo (1 o 2). Al guardar, las cards vuelven
  /// posicionadas en ella — nunca al principio.
  final int editingCard;

  /// La pantalla se está plegando hasta convertirse en su card. Lo enciende
  /// [startFold] y lo apaga [closeBlock]; la duración la pone el widget.
  final bool folding;

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

  /// ¿Está respondido ese paso? Nombre y sentimiento son requeridos; edad y
  /// peques son opcionales (saltarlos siempre está permitido); los pasos del
  /// día piden su respuesta.
  ///
  /// Es la ÚNICA tabla de reglas: la usan tanto avanzar de paso como habilitar
  /// el "Save" de una card. Con dos copias, editar acabaría admitiendo lo que
  /// el flujo no admite.
  bool isStepAnswered(int step) {
    return switch (step) {
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

  /// ¿Puede avanzar desde el paso actual?
  bool get canContinue => isStepAnswered(stepIndex);

  /// ¿Está entero el bloque? Es lo que habilita "Save" al corregir una card,
  /// donde no hay un paso actual al que preguntar.
  bool isBlockComplete(int block) =>
      (block == 1 ? kBlock1Steps : kBlock2Steps).every(isStepAnswered);

  /// Bloque al que pertenece el paso actual.
  int get block => kBlock1Steps.contains(stepIndex) ? 1 : 2;

  /// Posición dentro del bloque, 1-indexada: el contador dice "Step 2 of 4".
  int get stepInBlock => block == 1 ? stepIndex + 1 : stepIndex - 3;

  /// Cuántos pasos tiene el bloque actual (4 y 3): los puntos de progreso.
  int get stepsInBlock => block == 1 ? kBlock1Steps.length : kBlock2Steps.length;

  /// Último paso de su bloque: ahí el botón deja de decir "Continue" y cierra
  /// la card.
  bool get isLastStepOfBlock =>
      stepIndex == kBlock1Steps.last || stepIndex == kBlock2Steps.last;

  OnboardingState copyWith({
    int? stepIndex,
    OnboardingView? view,
    int? editingCard,
    bool? folding,
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
      view: view ?? this.view,
      editingCard: editingCard ?? this.editingCard,
      folding: folding ?? this.folding,
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

  /// Avanza un paso DENTRO del bloque. Cruzar al siguiente ya no es avanzar:
  /// es cerrar la card, y eso lo hace [closeBlock] tras el pliegue.
  void next() {
    if (!state.canContinue || state.isLastStepOfBlock) return;
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

  /// Arranca el pliegue de la pantalla hasta su card. Aquí solo se marca, para
  /// que el pie se aparte; la duración la pone el widget que anima.
  void startFold() {
    if (state.folding) return;
    state = state.copyWith(folding: true);
  }

  /// Fin del pliegue: el bloque 1 da paso al 2 y el 2 a las dos cards. No
  /// toca ninguna respuesta — plegar es un gesto de vista, no un envío.
  void closeBlock() {
    final toCards = state.view == OnboardingView.block2;
    state = state.copyWith(
      view: toCards ? OnboardingView.cards : OnboardingView.block2,
      folding: false,
      stepIndex: toCards ? state.stepIndex : kBlock2Steps.first,
    );
  }

  /// Abre una card a pantalla completa para corregirla.
  void openCard(int card) {
    if (card != 1 && card != 2) return;
    state = state.copyWith(view: OnboardingView.editing, editingCard: card);
  }

  /// Cierra la edición y vuelve a las cards, JAMÁS al flujo de pasos: quien
  /// entró a corregir una palabra no quiere repetir el recorrido entero. Con
  /// el bloque incompleto no se guarda — el botón ya sale apagado.
  void saveCard() {
    if (!state.isBlockComplete(state.editingCard)) return;
    state = state.copyWith(view: OnboardingView.cards);
  }

  /// Pasa al contrato emocional. Solo tras un POST resuelto.
  void toContract() => state = state.copyWith(view: OnboardingView.contract);

  /// Envía el onboarding. Solo construible si los tres requeridos están; la UI
  /// impide llegar aquí incompleta, pero lo reverificamos por seguridad.
  Future<void> submit() async {
    // Un segundo toque mientras el POST vuela crearía dos onboardings. El
    // botón ya sale en carga, pero esto lo cierra de verdad.
    if (state.isSubmitting) return;
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
      // Éxito: se muestra el contrato emocional (SPEC V2 §3.2). NO se marca
      // completo aún — eso lo dispara la usuaria con "Entrar a mi espacio".
      state = state.copyWith(isSubmitting: false, completed: true);
      toContract();
    } on Failure catch (failure) {
      state = state.copyWith(isSubmitting: false, errorMessage: failure.message);
    }
  }

  /// Cierra el contrato emocional: marca el onboarding completo y el router
  /// redirige a Home ("Empezamos cuando quieras").
  void enterSpace() =>
      ref.read(onboardingStatusProvider.notifier).markComplete();
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
  /// Excepción: 401 = la sesión guardada ya no vale (p. ej. cuenta eliminada
  /// en el servidor) — se limpia y el router vuelve al login, en vez de dejar
  /// el splash esperando para siempre.
  Future<void> refresh() async {
    try {
      final completed = await ref.read(onboardingRepositoryProvider).isCompleted();
      state = completed ? OnboardingStatus.complete : OnboardingStatus.incomplete;
    } on ApiFailure catch (failure) {
      if (failure.httpStatus == 401) {
        await ref.read(authControllerProvider.notifier).logout();
      } else {
        state = OnboardingStatus.unknown;
      }
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
