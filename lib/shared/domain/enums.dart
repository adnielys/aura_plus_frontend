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
  energy('energy', 'Con energía'),
  tranquil('tranquil', 'Tranquila'),
  scattered('scattered', 'Dispersa'),
  exhausted('exhausted', 'Agotada'),
  hard('hard', 'Al límite');

  const EmotionalState(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static EmotionalState fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Tiempo disponible al día. Contrato: `[minimal, short, medium]`.
enum TimeSlot {
  minimal('minimal', 'Casi nada (5 min)'),
  short('short', '10–20 minutos'),
  medium('medium', '30 minutos o más');

  const TimeSlot(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static TimeSlot fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Momento preferido del día. Contrato: `[early_morning, morning, midday, night]`.
enum PreferredMoment {
  earlyMorning('early_morning', 'Temprano, antes de que despierten'),
  morning('morning', 'Por la mañana'),
  midday('midday', 'Al mediodía'),
  night('night', 'De noche, cuando duermen');

  const PreferredMoment(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static PreferredMoment fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Lo que más pesa hoy. Contrato: `[work, family, self, relationships, all]`.
enum MainPain {
  work('work', 'El trabajo'),
  family('family', 'Mi familia y hogar'),
  self('self', 'Yo misma'),
  relationships('relationships', 'Mis relaciones'),
  all('all', 'Todo a la vez');

  const MainPain(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static MainPain fromWire(String value) =>
      values.firstWhere((e) => e.wireValue == value);
}

/// Edades de los hijos (multi-selección). Contrato: `[baby, small, school, teen]`.
enum ChildAge {
  baby('baby', 'Bebé (0–2)'),
  small('small', 'Pequeños (3–7)'),
  school('school', 'Escolares (8–12)'),
  teen('teen', 'Adolescentes');

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
