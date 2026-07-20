import 'package:aura_plus/features/profile/presentation/providers/area_gestures_provider.dart';
import 'package:aura_plus/shared/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('areaGestureFromJson (Mis áreas M3)', () {
    test('parsea el contrato completo', () {
      final gesture = areaGestureFromJson({
        'date': '2026-07-18',
        'habit_id': 'h1',
        'title': 'Cuento antes de dormir',
        'icon': 'storytelling',
        'area': 'family',
        'result': 'partial',
      });
      expect(gesture.date, DateTime(2026, 7, 18));
      expect(gesture.area, HabitArea.family);
      expect(gesture.result, HabitResult.partial);
      expect(gesture.result.label, 'Halfway');
    });

    test('"no fue posible" viaja con la misma dignidad (parse normal)', () {
      final gesture = areaGestureFromJson({
        'date': '2026-07-12',
        'habit_id': 'h2',
        'title': 'Desayunar sin prisa',
        'icon': null,
        'area': 'family',
        'result': 'not_possible',
      });
      expect(gesture.result, HabitResult.notPossible);
      expect(gesture.icon, isNull);
    });
  });
}
