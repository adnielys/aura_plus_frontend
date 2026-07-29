import '../../../../shared/domain/enums.dart';

/// Reflejo emocional del paso "¿qué es lo que más pesa?" (SPEC V2 §3.1).
///
/// La PRIMERA vez que Aura responde a algo que ella contó: valida la
/// elección, jamás aconseja ni exige. Textos aprobados (jul 2026, inglés).
/// Mapa constante y testeable: 5/5 sin strings vacíos.
const Map<MainPain, String> painReflections = {
  MainPain.work:
      'When work fills everything, a space of your own becomes more '
      'necessary — not less.',
  MainPain.family: "Holding a home together is invisible work. Here, it's seen.",
  MainPain.self: 'Putting yourself on the list is already a good start.',
  MainPain.relationships: "Bonds get tired too. We'll take it slowly.",
  MainPain.all:
      "When everything weighs at once, starting small isn't settling — "
      "it's wisdom.",
};
