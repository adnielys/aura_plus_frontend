import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/features/check_in/domain/entities/check_in_result.dart';
import 'package:aura_plus/features/check_in/presentation/widgets/habit_card.dart';
import 'package:aura_plus/shared/domain/enums.dart';

const _habit = Habit(
  id: 'h1',
  title: 'Tea + a pause',
  auraCopy: '',
  area: HabitArea.self,
  durationMinutes: 6,
);

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('día abierto: la franja ofrece las MISMAS 3 opciones del cierre',
      (tester) async {
    await tester.pumpWidget(_wrap(
      HabitCard(habit: _habit, result: null, onMark: (_) {}),
    ));
    for (final option in HabitResult.values) {
      expect(find.text(option.label), findsOneWidget);
    }
  });

  testWidgets('día cerrado: 3 chips y la registrada queda tachada',
      (tester) async {
    await tester.pumpWidget(_wrap(
      HabitCard(
        habit: _habit,
        result: null,
        onMark: (_) {},
        closedResult: HabitResult.partial,
      ),
    ));
    for (final option in HabitResult.values) {
      expect(find.text(option.label), findsOneWidget);
    }
    final chosen = tester.widget<Text>(find.text(HabitResult.partial.label));
    expect(chosen.style?.decoration, TextDecoration.lineThrough);
    // Las no elegidas no se tachan: solo se apagan.
    final other = tester.widget<Text>(find.text(HabitResult.done.label));
    expect(other.style?.decoration, isNot(TextDecoration.lineThrough));
  });
}
