import '../../domain/constellation.dart';

/// DTO de [Constellation]: conoce el JSON del contrato (`Constellation` en
/// openapi.yaml). Transversal porque lo devuelven `/constellation/*` y
/// `SessionResult` (features distintas que no pueden importarse entre sí).
class ConstellationModel extends Constellation {
  const ConstellationModel({
    required super.id,
    required super.name,
    required super.cycleNumber,
    required super.starsEarned,
    required super.starsMax,
    required super.isComplete,
    required super.isCurrent,
    super.completedAt,
    super.daysPresent,
  });

  /// Construye desde el contenido ya desenvuelto del envelope.
  factory ConstellationModel.fromJson(Map<dynamic, dynamic> json) {
    final completedAt = json['completed_at'] as String?;
    return ConstellationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      cycleNumber: (json['cycle_number'] as int?) ?? 1,
      starsEarned: (json['stars_earned'] as int?) ?? 0,
      starsMax: (json['stars_max'] as int?) ?? 9,
      isComplete: (json['is_complete'] as bool?) ?? false,
      isCurrent: (json['is_current'] as bool?) ?? true,
      completedAt: completedAt == null ? null : DateTime.tryParse(completedAt),
      daysPresent: json['days_present'] as int?,
    );
  }
}
