import 'package:aura_plus/shared/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prettyDate', () {
    test('formatea sin año: cercanía, no expediente', () {
      expect(prettyDate(DateTime(2026, 7, 18)), 'July 18');
      expect(prettyDate(DateTime(2026, 1, 2)), 'January 2');
    });
  });

  group('weekdayName', () {
    test('lunes = 1 … domingo = 7', () {
      expect(weekdayName(DateTime(2026, 7, 20)), 'Monday');
      expect(weekdayName(DateTime(2026, 7, 16)), 'Thursday');
      expect(weekdayName(DateTime(2026, 7, 19)), 'Sunday');
    });
  });

  group('relativeDate (fechas cercanas, no expediente)', () {
    final today = DateTime(2026, 7, 19);

    test('hoy y ayer', () {
      expect(relativeDate(DateTime(2026, 7, 19), today), 'today');
      expect(relativeDate(DateTime(2026, 7, 18), today), 'yesterday');
    });

    test('más atrás: "Mes N", sin año', () {
      expect(relativeDate(DateTime(2026, 7, 12), today), 'July 12');
      expect(relativeDate(DateTime(2026, 6, 30), today), 'June 30');
    });
  });
}
