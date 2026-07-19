import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/utils/text_search.dart';

/// Un microhábito del catálogo (`GET /habits`, schema `Habit` del contrato).
/// Lista informativa: el motor sigue eligiendo por estado emocional.
///
/// Hábitos v2: `visibility` + `isMine` pintan los badges "tuyo" /
/// "tuyo · en revisión". Lo suyo es suyo desde el primer segundo — la
/// revisión solo decide si el banco común lo ve.
typedef CatalogHabit = ({
  String id,
  String title,
  String auraCopy,
  HabitArea area,
  int durationMinutes,
  String? icon,
  String visibility, // private | pending_review | public
  bool isMine,
});

CatalogHabit catalogHabitFromJson(Map<Object?, Object?> json) => (
      id: json['id'] as String,
      title: json['title'] as String,
      auraCopy: (json['aura_copy'] as String?) ?? '',
      area: HabitArea.fromWire(json['area'] as String),
      durationMinutes: (json['duration_minutes'] as int?) ?? 0,
      icon: json['icon'] as String?,
      visibility: (json['visibility'] as String?) ?? 'public',
      isMine: (json['is_mine'] as bool?) ?? false,
    );

/// Filtro en vivo del catálogo (H1/H2): [query] busca en el título (sin
/// mayúsculas ni acentos) y [area] restringe; se combinan.
List<CatalogHabit> filterCatalog(
  List<CatalogHabit> habits, {
  String query = '',
  HabitArea? area,
}) {
  final folded = foldSearch(query.trim());
  return [
    for (final habit in habits)
      if ((area == null || habit.area == area) &&
          (folded.isEmpty || foldSearch(habit.title).contains(folded)))
        habit,
  ];
}

/// Separa LOS SUYOS del resto conservando el orden: los suyos van SIEMPRE
/// primero en catálogo y selector ⇄ — lo que ella creó jamás queda enterrado
/// entre 120 gestos de la casa.
({List<CatalogHabit> mine, List<CatalogHabit> rest}) splitMine(
  List<CatalogHabit> habits,
) =>
    (
      mine: [
        for (final habit in habits)
          if (habit.isMine) habit,
      ],
      rest: [
        for (final habit in habits)
          if (!habit.isMine) habit,
      ],
    );

/// Catálogo visible: banco público + LOS SUYOS (private/pending), ordenado
/// por área en el servidor.
final habitsCatalogProvider = FutureProvider<List<CatalogHabit>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/habits');
  final body = unwrapEnvelope(response.data);
  return [
    for (final item in (body as List? ?? const []))
      catalogHabitFromJson(item as Map),
  ];
});

/// Crea un microhábito propio (`POST /habits`). Con [share] pide llevarlo al
/// banco común (nace pending_review); sin él es privado para siempre. En
/// ambos casos, para ELLA queda disponible al instante.
Future<CatalogHabit> createHabit(
  WidgetRef ref, {
  required String title,
  required HabitArea area,
  required int durationMinutes,
  required bool share,
}) async {
  final dio = ref.read(dioProvider);
  final response = await dio.post<Object?>('/habits', data: {
    'title': title,
    'area': area.wireValue,
    'duration_minutes': durationMinutes,
    'share': share,
  });
  final body = unwrapEnvelope(response.data) as Map;
  ref.invalidate(habitsCatalogProvider);
  return catalogHabitFromJson(body);
}
