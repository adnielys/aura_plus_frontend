import '../../../../shared/domain/constellation.dart';
import '../../../../shared/domain/enums.dart';

/// Sesión de cierre del día. Las estrellas las calcula el SERVIDOR
/// (GUARD_STAR_02: el cliente jamás las envía ni recalcula).
class DailySession {
  const DailySession({
    required this.id,
    required this.date,
    required this.habit1Result,
    required this.starsEarned,
    required this.closingMessage,
    this.habit2Result,
    this.reflection,
  });

  final String id;
  final DateTime date;
  final HabitResult habit1Result;
  final HabitResult? habit2Result;
  final String? reflection;
  final int starsEarned;

  /// Mensaje de cierre escrito por el servidor (tono cálido, sin culpa).
  final String closingMessage;
}

/// Resultado del cierre (reconciliación #3): sesión + constelación actualizada,
/// sin GETs extra.
class SessionResult {
  const SessionResult({required this.session, required this.constellation});

  final DailySession session;
  final Constellation constellation;
}
