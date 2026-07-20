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

  /// Sublabel del check-in según DECISION_CHECKIN_ESCALA_ESTADOS
  /// (reconciliación #12): 5 estados cualitativos con idéntica dignidad,
  /// sin orden implícito ni gradiente de energía.
  String get checkInHint => switch (this) {
        EmotionalState.energy => 'Lista para avanzar hoy',
        EmotionalState.tranquil => 'En modo sostenido',
        EmotionalState.scattered => 'La mente va en mil direcciones',
        EmotionalState.exhausted => 'Pide pausa',
        EmotionalState.hard => 'Weighs most today',
      };
}
