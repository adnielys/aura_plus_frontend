import 'package:aura_plus/features/profile/presentation/providers/history_provider.dart';
import 'package:aura_plus/shared/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryDay _day(DateTime date, {bool closed = true, int gestures = 2}) => (
      date: date,
      starsEarned: closed ? 5 : 0,
      state: EmotionalState.energy,
      hadSession: closed,
      gesturesCount: gestures,
    );

void main() {
  group('groupHistory (Esta semana / Antes)', () {
    final today = DateTime(2026, 7, 20);

    test('últimos 7 días a Esta semana; el resto a Antes; orden intacto', () {
      final days = [
        _day(DateTime(2026, 7, 20)),
        _day(DateTime(2026, 7, 14)), // hace 6 días: aún esta semana
        _day(DateTime(2026, 7, 13)), // hace 7: antes
        _day(DateTime(2026, 6, 25)),
      ];
      final (thisWeek: thisWeek, earlier: earlier) = groupHistory(days, today);
      expect(thisWeek.map((d) => d.date.day), [20, 14]);
      expect(earlier.map((d) => d.date.day), [13, 25]);
    });

    test('sin días: ambos grupos vacíos (nada que fingir)', () {
      final (thisWeek: thisWeek, earlier: earlier) = groupHistory([], today);
      expect(thisWeek, isEmpty);
      expect(earlier, isEmpty);
    });
  });

  group('groupHistoryMonths (historia total Q3)', () {
    final today = DateTime(2026, 7, 20);

    test('THIS WEEK primero y después una sección por mes, en orden', () {
      final days = [
        _day(DateTime(2026, 7, 20)),
        _day(DateTime(2026, 7, 13)), // hace 7 días: ya no es "esta semana"
        _day(DateTime(2026, 6, 28)),
        _day(DateTime(2026, 6, 2)),
        _day(DateTime(2025, 12, 24)), // año anterior: lleva el año
      ];
      final sections = groupHistoryMonths(days, today);
      expect(sections.map((s) => s.label),
          ['THIS WEEK', 'JULY', 'JUNE', 'DECEMBER 2025']);
      expect(sections[0].days.map((d) => d.date.day), [20]);
      expect(sections[1].days.map((d) => d.date.day), [13]);
      expect(sections[2].days.map((d) => d.date.day), [28, 2]);
      expect(sections[3].days.map((d) => d.date.day), [24]);
    });

    test('sin presencia esta semana no se inventa la sección', () {
      final sections =
          groupHistoryMonths([_day(DateTime(2026, 5, 9))], today);
      expect(sections.map((s) => s.label), ['MAY']);
    });

    test('sin días: sin secciones', () {
      expect(groupHistoryMonths([], today), isEmpty);
    });
  });
}
