import 'package:aura_plus/core/notifications/local_daily_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('messageForDay (pool rotatorio de la diaria local)', () {
    test('rotación estable por día del año, sin repetir seguido', () {
      final a = messageForDay(DateTime(2026, 7, 20));
      final b = messageForDay(DateTime(2026, 7, 21));
      final c = messageForDay(DateTime(2026, 7, 22));
      expect(a, isNot(b));
      expect(b, isNot(c));
      // Determinista: el mismo día siempre da el mismo copy.
      expect(messageForDay(DateTime(2026, 7, 20)), a);
    });

    test('todo el pool invita, jamás exige (guard de tono básico)', () {
      for (final message in dailyMessages) {
        final lower = message.toLowerCase();
        for (final forbidden in [
          'must', 'should', 'don\'t forget', 'missed', 'streak', 'behind',
        ]) {
          expect(lower.contains(forbidden), isFalse,
              reason: '"$message" contiene "$forbidden"');
        }
      }
    });
  });
}
