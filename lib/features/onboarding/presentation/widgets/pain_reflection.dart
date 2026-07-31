/// Reflejos del onboarding (SPEC V2 §3.1 + ampliación jul 2026): Aura
/// responde a CADA elección validándola — jamás una vara de medir que deje
/// corta una opción (la lección del "ten minutes" fijo con 5 min elegidos).
/// Mapas constantes y testeables, sin strings vacíos.
library;

import '../../../../shared/domain/enums.dart';

/// Paso "¿qué es lo que más pesa?" — textos aprobados (5/5).
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

/// Paso "¿cuánto tiempo tienes?" — cada número es suficiente TAL CUAL
/// (el motor jamás pide más del 70%+5 de lo declarado: el tercer texto es
/// literalmente cierto por diseño, BE-20). Textos aprobados (3/3).
const Map<TimeSlot, String> timeReflections = {
  TimeSlot.minimal: "Five minutes is not little — it's a door. Aura fits inside it.",
  TimeSlot.short: 'Ten minutes a day is enough to build something that matters.',
  TimeSlot.medium: 'That time is yours. Aura will never ask for all of it.',
};

/// Sin selección aún: neutro, sin benchmark.
const String timeReflectionDefault = 'Aura+ adapts to what you have.';

/// Paso "¿cuándo es tu momento?" — la PROMESA (1 mensaje/día, máximo) es
/// idéntica en las 4; solo se tiñe del momento elegido. Aprobados (4/4).
const Map<PreferredMoment, String> momentReflections = {
  PreferredMoment.earlyMorning:
      'One message a day, before the noise. Nothing more.',
  PreferredMoment.morning:
      'One message a day, once the day is rolling. Nothing more.',
  PreferredMoment.midday:
      'One message a day, as a pause in the middle. Nothing more.',
  PreferredMoment.night:
      'One message a day, when the house sleeps. Nothing more.',
};

/// Sin selección aún: la promesa a secas.
const String momentReflectionDefault =
    'One message a day, at this moment. Nothing more.';
