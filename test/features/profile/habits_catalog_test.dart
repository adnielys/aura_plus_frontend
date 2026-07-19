import 'package:aura_plus/features/profile/presentation/providers/habits_catalog_provider.dart';
import 'package:aura_plus/shared/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogHabit _habit(
  String title,
  HabitArea area, {
  String visibility = 'public',
  bool mine = false,
}) =>
    (
      id: title,
      title: title,
      auraCopy: '',
      area: area,
      durationMinutes: 5,
      icon: null,
      visibility: visibility,
      isMine: mine,
    );

void main() {
  group('catalogHabitFromJson (Hábitos v2)', () {
    test('parsea visibility + is_mine y tolera su ausencia (catálogo base)', () {
      final mine = catalogHabitFromJson({
        'id': 'h1',
        'title': 'Café sin pantallas',
        'area': 'self',
        'duration_minutes': 10,
        'visibility': 'pending_review',
        'is_mine': true,
      });
      expect(mine.visibility, 'pending_review');
      expect(mine.isMine, isTrue);

      final base = catalogHabitFromJson({
        'id': 'h2',
        'title': 'Beber agua',
        'area': 'self',
        'duration_minutes': 5,
      });
      expect(base.visibility, 'public');
      expect(base.isMine, isFalse);
    });
  });

  group('filterCatalog (buscador H1: texto + área combinables)', () {
    final all = [
      _habit('Beber un vaso de agua', HabitArea.self),
      _habit('Café sin pantallas', HabitArea.self, mine: true),
      _habit('Pintar con mi hija', HabitArea.family),
    ];

    test('por texto, sin distinguir mayúsculas ni acentos', () {
      expect(filterCatalog(all, query: 'cafe').single.title,
          'Café sin pantallas');
      expect(filterCatalog(all, query: 'PINTAR').single.area,
          HabitArea.family);
    });

    test('texto y área se combinan; sin filtros devuelve todo', () {
      expect(filterCatalog(all, query: 'pintar', area: HabitArea.self),
          isEmpty);
      expect(
          filterCatalog(all, area: HabitArea.self).length, 2);
      expect(filterCatalog(all), all);
    });

    test('sin resultados = lista vacía (la UI invita a crear)', () {
      expect(filterCatalog(all, query: 'nada-así'), isEmpty);
    });
  });

  group('splitMine (los suyos siempre primero, jamás enterrados)', () {
    test('separa conservando el orden', () {
      final all = [
        _habit('De la casa 1', HabitArea.self),
        _habit('Mío privado', HabitArea.self, mine: true, visibility: 'private'),
        _habit('De la casa 2', HabitArea.family),
        _habit('Mío en revisión', HabitArea.family,
            mine: true, visibility: 'pending_review'),
      ];
      final (mine: mine, rest: rest) = splitMine(all);
      expect(mine.map((h) => h.title),
          ['Mío privado', 'Mío en revisión']);
      expect(rest.map((h) => h.title), ['De la casa 1', 'De la casa 2']);
    });

    test('sin suyos: mine vacío y el banco intacto', () {
      final all = [_habit('De la casa', HabitArea.self)];
      final (mine: mine, rest: rest) = splitMine(all);
      expect(mine, isEmpty);
      expect(rest, all);
    });
  });
}
