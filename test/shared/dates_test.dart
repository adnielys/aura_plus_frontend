import 'package:aura_plus/shared/utils/dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('spanishDate', () {
    test('formatea sin año: cercanía, no expediente', () {
      expect(spanishDate(DateTime(2026, 7, 18)), '18 de julio');
      expect(spanishDate(DateTime(2026, 1, 2)), '2 de enero');
    });
  });

  group('relativeSpanishDate (fechas cercanas, no expediente)', () {
    final today = DateTime(2026, 7, 19);

    test('hoy y ayer', () {
      expect(relativeSpanishDate(DateTime(2026, 7, 19), today), 'hoy');
      expect(relativeSpanishDate(DateTime(2026, 7, 18), today), 'ayer');
    });

    test('más atrás: "N de mes", sin año', () {
      expect(relativeSpanishDate(DateTime(2026, 7, 12), today), '12 de julio');
      expect(relativeSpanishDate(DateTime(2026, 6, 30), today), '30 de junio');
    });
  });
}
