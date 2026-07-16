import '../../../../shared/domain/enums.dart';
import '../entities/session_result.dart';

/// Contrato del repositorio de cierre del día.
abstract interface class SessionRepository {
  /// Cierra el día. Si ya estaba cerrado, el backend devuelve la sesión
  /// existente (GUARD_SESSION_01) — nunca es un error.
  Future<SessionResult> close({
    required HabitResult habit1Result,
    HabitResult? habit2Result,
    String? reflection,
  });
}
