import '../../../../shared/domain/enums.dart';

/// Visuales del check-in (maquetado `aura_preview`): ilustración y subtítulo
/// por estado. El ORDEN de [checkInOrder] es el del maquetado, de más a menos
/// energía. Solo presentación: los valores del contrato viven en el enum.
const List<EmotionalState> checkInOrder = [
  EmotionalState.energy,
  EmotionalState.tranquil,
  EmotionalState.scattered,
  EmotionalState.exhausted,
  EmotionalState.hard,
];

extension EnergyVisuals on EmotionalState {
  /// Ilustración del maquetado para la tarjeta del estado.
  String get imageAsset => switch (this) {
        EmotionalState.energy => 'assets/images/energy/energized.jpg',
        EmotionalState.tranquil => 'assets/images/energy/steady.jpg',
        EmotionalState.scattered => 'assets/images/energy/soso.jpg',
        EmotionalState.exhausted => 'assets/images/energy/low.jpg',
        EmotionalState.hard => 'assets/images/energy/empty.jpg',
      };

  /// Hero del día (maquetado): tras el check-in, el Home y la recomendación
  /// muestran la ilustración del estado elegido (mircrohabitos/{estado}.png).
  String get recoHeroAsset => switch (this) {
        EmotionalState.energy => 'assets/images/reco/energized.png',
        EmotionalState.tranquil => 'assets/images/reco/steady.png',
        EmotionalState.scattered => 'assets/images/reco/soso.png',
        EmotionalState.exhausted => 'assets/images/reco/low.png',
        EmotionalState.hard => 'assets/images/reco/empty.png',
      };

  /// Etiqueta del estado EN EL CHECK-IN (maquetado "How much energy today?").
  ///
  /// REGLA (DECISION_CHECKIN_ESCALA_ESTADOS + revisión jul 2026): el título
  /// nombra EL DÍA, jamás a ella — "At the limit" es un lugar donde se está
  /// hoy; "Empty" sería algo que se es. Y `scattered` conserva su nombre: no
  /// es un peldaño intermedio, es una energía distinta (la hay, va en cinco
  /// direcciones). Mismos nombres que la historia, el export y el Home: un
  /// día no puede llamarse de dos formas según la pantalla.
  String get checkInLabel => switch (this) {
        EmotionalState.energy => 'Energized',
        EmotionalState.tranquil => 'Calm',
        EmotionalState.scattered => 'Scattered',
        EmotionalState.exhausted => 'Tired',
        EmotionalState.hard => 'At the limit',
      };

  /// Sublabel del check-in: promesa de lo que Aura hará con su día (nunca un
  /// diagnóstico de ella).
  String get checkInHint => switch (this) {
        EmotionalState.energy => 'Room for a bit more',
        EmotionalState.tranquil => 'A couple of gentle steps',
        EmotionalState.scattered => 'Keep it light',
        EmotionalState.exhausted => 'Just one small thing',
        EmotionalState.hard => 'Today, only rest',
      };
}
