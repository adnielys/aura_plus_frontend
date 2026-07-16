import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/enums.dart';

/// Borrador del cierre del día: los resultados que la usuaria va marcando
/// (Done / Not today) en la recomendación o en el Home, por id de hábito.
/// Es estado de UI compartido entre pantallas; el cierre real lo hace
/// [SessionController] con estos valores.
final sessionDraftProvider =
    NotifierProvider<SessionDraftController, Map<String, HabitResult>>(
  SessionDraftController.new,
);

class SessionDraftController extends Notifier<Map<String, HabitResult>> {
  @override
  Map<String, HabitResult> build() => const {};

  void setResult(String habitId, HabitResult result) =>
      state = {...state, habitId: result};

  void clear() => state = const {};
}
