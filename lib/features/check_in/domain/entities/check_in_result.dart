import '../../../../shared/domain/enums.dart';

/// Check-in del día. El estado es INMUTABLE una vez registrado
/// (GUARD_CHECKIN_01: repetir devuelve el existente).
class CheckIn {
  const CheckIn({required this.id, required this.date, required this.emotionalState});

  final String id;
  final DateTime date;
  final EmotionalState emotionalState;
}

/// Microhábito recomendado por el SERVIDOR (el cliente nunca elige por su
/// cuenta en el MVP; ver reconciliación #2).
class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.auraCopy,
    required this.area,
    required this.durationMinutes,
    this.icon,
  });

  final String id;
  final String title;

  /// Frase de Aura que acompaña al hábito (tono cálido, del servidor).
  final String auraCopy;
  final HabitArea area;
  final int durationMinutes;

  /// Icono propio del hábito (nombre icons8 del maquetado); null → el del área.
  final String? icon;
}

/// Recomendación del día: 1 o 2 hábitos. `habit2` nulo = modo CARE/ANCHOR
/// (reconciliación #4): hoy solo una cosa pequeña.
class Recommendation {
  const Recommendation({required this.id, required this.habit1, this.habit2});

  final String id;
  final Habit habit1;
  final Habit? habit2;

  List<Habit> get habits => [habit1, ?habit2];
}

/// Mensajes del sistema para el flujo del día (los escribe el servidor).
class SystemMessages {
  const SystemMessages({required this.startOfDay, required this.recommendation});

  final String startOfDay;
  final String recommendation;
}

/// Resultado del check-in (reconciliación #2): llega TODO junto, sin GETs extra.
class CheckInResult {
  const CheckInResult({
    required this.checkIn,
    required this.recommendation,
    required this.messages,
  });

  final CheckIn checkIn;
  final Recommendation recommendation;
  final SystemMessages messages;
}
