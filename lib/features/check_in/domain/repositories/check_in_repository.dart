import '../../../../shared/domain/enums.dart';
import '../entities/check_in_result.dart';

/// Contrato del repositorio de check-in (implementación en `data`).
abstract interface class CheckInRepository {
  /// Registra el estado de hoy. Si ya había check-in, el backend devuelve el
  /// existente (GUARD_CHECKIN_01) — nunca es un error.
  Future<CheckInResult> submit(EmotionalState state);

  /// El resultado de hoy (check-in + recomendación), o null si aún no hay
  /// check-in hoy.
  Future<CheckInResult?> today();
}
