import '../../../../shared/data/models/constellation_model.dart';
import '../../../../shared/domain/enums.dart';
import '../../domain/entities/session_result.dart';

/// DTOs del contrato para el cierre del día (contenido ya desenvuelto).
class DailySessionModel extends DailySession {
  const DailySessionModel({
    required super.id,
    required super.date,
    required super.habit1Result,
    required super.starsEarned,
    required super.closingMessage,
    super.habit2Result,
    super.reflection,
  });

  factory DailySessionModel.fromJson(Map<dynamic, dynamic> json) {
    final habit2 = json['habit_2_result'] as String?;
    return DailySessionModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      habit1Result: HabitResult.fromWire(json['habit_1_result'] as String),
      habit2Result: habit2 == null ? null : HabitResult.fromWire(habit2),
      reflection: json['reflection'] as String?,
      starsEarned: (json['stars_earned'] as int?) ?? 0,
      closingMessage: (json['closing_message'] as String?) ?? '',
    );
  }
}

class SessionResultModel extends SessionResult {
  const SessionResultModel({required super.session, required super.constellation});

  factory SessionResultModel.fromJson(Map<dynamic, dynamic> json) =>
      SessionResultModel(
        session: DailySessionModel.fromJson(json['session'] as Map),
        constellation:
            ConstellationModel.fromJson(json['constellation'] as Map),
      );
}
