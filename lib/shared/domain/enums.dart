/// Enums centrales del dominio, compartidos entre features (onboarding, check-in,
/// daily flow…). Viven en `shared/` porque son transversales.
///
/// Cada valor lleva su [wireValue] (lo que viaja en el contrato, snake_case) y su
/// [label] en español para la UI. El mapeo es EXPLÍCITO (reconciliación #7): nunca
/// se confía en `.name` para hablar con el backend, porque divergen
/// (`early_morning` ≠ `earlyMorning`).
library;

/// Estado emocional del check-in y del sentimiento inicial del onboarding.
/// Contrato: `[energy, tranquil, scattered, exhausted, hard]`.
enum EmotionalState {
  energy('energy', 'Energized'),
  tranquil('tranquil', 'Calm'),
  scattered('scattered', 'Scattered'),
  exhausted('exhausted', 'Exhausted'),
  hard('hard', 'At the limit');

  const EmotionalState(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static EmotionalState fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Tiempo disponible al día. Contrato: `[minimal, short, medium]`.
enum TimeSlot {
  minimal('minimal', 'Almost none (5 min)'),
  short('short', 'A little while (10–20 min)'),
  medium('medium', 'Some time (30 min+)');

  const TimeSlot(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static TimeSlot fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Momento preferido del día. Contrato: `[early_morning, morning, midday, night]`.
enum PreferredMoment {
  earlyMorning('early_morning', 'Early, before they wake up'),
  morning('morning', 'In the morning'),
  midday('midday', 'At midday'),
  night('night', 'At night, when they sleep');

  const PreferredMoment(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static PreferredMoment fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Lo que más pesa hoy. Contrato: `[work, family, self, relationships, all]`.
enum MainPain {
  work('work', 'Work'),
  family('family', 'My family and home'),
  self('self', 'Myself'),
  relationships('relationships', 'My relationships'),
  all('all', 'Everything at once');

  const MainPain(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static MainPain fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Sentimientos del onboarding (multi-selección, contrato `initial_feelings`).
/// Dato de contexto: no alimenta motores. El backend descarta valores
/// desconocidos con validación laxa.
enum Feeling {
  exhausted('exhausted', 'Exhausted'),
  overwhelmed('overwhelmed', 'Overwhelmed'),
  noTimeForMyself('no_time_for_myself', 'No time for myself'),
  guilty('guilty', 'Guilty'),
  anxious('anxious', 'Anxious'),
  frustrated('frustrated', 'Frustrated'),
  sad('sad', 'Sad'),
  invisible('invisible', 'Invisible'),
  impatient('impatient', 'Impatient'),
  lonely('lonely', 'Lonely'),
  hopeful('hopeful', 'Hopeful'),
  calm('calm', 'Calm'),
  grateful('grateful', 'Grateful'),
  proud('proud', 'Proud'),
  judged('judged', 'Judged');

  const Feeling(this.wireValue, this.label);

  final String wireValue;
  final String label;

  /// Ilustración del maquetado (aura_preview · sentimientos/).
  String get imageAsset => 'assets/images/feelings/$wireValue.png';
}

/// Área de vida de un hábito. Contrato: `[self, family, relationships, work]`.
enum HabitArea {
  self('self', 'Me'),
  family('family', 'Family'),
  relationships('relationships', 'Relationships'),
  work('work', 'Work');

  const HabitArea(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static HabitArea fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Resultado de un hábito al cerrar el día. Contrato: `[done, partial,
/// not_possible]`. "No fue posible" es una respuesta válida que también suma.
enum HabitResult {
  done('done', 'I did it'),
  partial('partial', 'Halfway'),
  notPossible('not_possible', 'Not possible');

  const HabitResult(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static HabitResult fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Edades de los hijos (multi-selección). Contrato: `[baby, small, school, teen]`.
enum ChildAge {
  baby('baby', 'Baby (0–2)'),
  small('small', 'Little ones (3–7)'),
  school('school', 'School age (8–12)'),
  teen('teen', 'Teens');

  const ChildAge(this.wireValue, this.label);

  final String wireValue;
  final String label;

  /// Tolerante: devuelve null si el backend manda un valor desconocido, para no
  /// romper el parseo del perfil por una edad nueva.
  static ChildAge? tryFromWire(String value) {
    for (final age in values) {
      if (age.wireValue == value) return age;
    }
    return null;
  }
}
