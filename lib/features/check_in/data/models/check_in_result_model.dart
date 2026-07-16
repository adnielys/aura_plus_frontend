import '../../../../shared/domain/enums.dart';
import '../../domain/entities/check_in_result.dart';

/// DTOs del contrato para el flujo de check-in. La capa `data` desenvuelve el
/// envelope ANTES de llegar aquí (reconciliación #1); estos factories reciben
/// el contenido de `data`.
class CheckInModel extends CheckIn {
  const CheckInModel({
    required super.id,
    required super.date,
    required super.emotionalState,
  });

  factory CheckInModel.fromJson(Map<dynamic, dynamic> json) => CheckInModel(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        emotionalState:
            EmotionalState.fromWire(json['emotional_state'] as String),
      );
}

class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.title,
    required super.auraCopy,
    required super.area,
    required super.durationMinutes,
    super.icon,
  });

  factory HabitModel.fromJson(Map<dynamic, dynamic> json) => HabitModel(
        id: json['id'] as String,
        title: json['title'] as String,
        auraCopy: (json['aura_copy'] as String?) ?? '',
        area: HabitArea.fromWire(json['area'] as String),
        durationMinutes: (json['duration_minutes'] as int?) ?? 5,
        icon: json['icon'] as String?,
      );
}

class RecommendationModel extends Recommendation {
  const RecommendationModel({
    required super.id,
    required super.habit1,
    super.habit2,
  });

  factory RecommendationModel.fromJson(Map<dynamic, dynamic> json) {
    final habit2 = json['habit_2'];
    return RecommendationModel(
      id: json['id'] as String,
      habit1: HabitModel.fromJson(json['habit_1'] as Map),
      habit2: habit2 == null ? null : HabitModel.fromJson(habit2 as Map),
    );
  }
}

class CheckInResultModel extends CheckInResult {
  const CheckInResultModel({
    required super.checkIn,
    required super.recommendation,
    required super.messages,
  });

  factory CheckInResultModel.fromJson(Map<dynamic, dynamic> json) {
    final messages = (json['messages'] as Map?) ?? const {};
    return CheckInResultModel(
      checkIn: CheckInModel.fromJson(json['check_in'] as Map),
      recommendation:
          RecommendationModel.fromJson(json['recommendation'] as Map),
      messages: SystemMessages(
        startOfDay: (messages['start_of_day'] as String?) ?? '',
        recommendation: (messages['recommendation'] as String?) ?? '',
      ),
    );
  }
}
