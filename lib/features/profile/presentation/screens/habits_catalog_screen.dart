import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/habit_icons.dart';
import '../providers/habits_catalog_provider.dart';

/// Estilo por área de vida (mismos tonos que las HabitCards de la reco).
/// El icono de cabecera es el del área; el de cada fila es el del HÁBITO.
typedef _AreaStyle = ({
  String name,
  Color bg,
  Color fg,
  Color iconBg,
  IconData icon,
});

const Map<HabitArea, _AreaStyle> _areaStyle = {
  HabitArea.self: (
    name: 'Me',
    bg: Color(0xFFFFE3EE),
    fg: Color(0xFFC01448),
    iconBg: Color(0xFFFFF0F4),
    icon: Icons.self_improvement,
  ),
  HabitArea.family: (
    name: 'Family',
    bg: Color(0xFFFCE9D6),
    fg: Color(0xFFE0894A),
    iconBg: Color(0xFFFFF6EE),
    icon: Icons.auto_stories,
  ),
  HabitArea.relationships: (
    name: 'Relationships',
    bg: Color(0xFFECE1FB),
    fg: Color(0xFF9B6FD4),
    iconBg: Color(0xFFF6F0FF),
    icon: Icons.favorite_border,
  ),
  HabitArea.work: (
    name: 'Work',
    bg: Color(0xFFDCE9F6),
    fg: Color(0xFF3F7CB0),
    iconBg: Color(0xFFEEF5FC),
    icon: Icons.work_outline,
  ),
};

/// Catálogo completo de microhábitos (fila "All microhabits" del perfil).
/// Solo lectura y sin marcar nada: la recomendación diaria sigue siendo del
/// motor; aquí ella solo hojea qué gestos existen. [initialArea] filtra a un
/// área (invitación desde "Tu cuidado, por áreas" del Home).
class HabitsCatalogScreen extends ConsumerStatefulWidget {
  const HabitsCatalogScreen({super.key, this.initialArea});

  final HabitArea? initialArea;

  @override
  ConsumerState<HabitsCatalogScreen> createState() =>
      _HabitsCatalogScreenState();
}

class _HabitsCatalogScreenState extends ConsumerState<HabitsCatalogScreen> {
  final _searchController = TextEditingController();
  HabitArea? _filter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialArea;
    // Refetch al entrar: si el admin publicó uno suyo, el badge pasa de
    // "en revisión" a "tuyo" sin reiniciar la app (sin aviso — nunca hay
    // notificación de revisión, ni buena ni mala).
    Future.microtask(() {
      if (mounted) ref.invalidate(habitsCatalogProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(habitsCatalogProvider);

    return Scaffold(
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(habitsCatalogProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (habits) {
          // Búsqueda por texto + chip de área, combinables (Hábitos v2).
          final visible = filterCatalog(habits, query: _query, area: _filter);
          // Los suyos SIEMPRE primero: jamás enterrados entre 120 gestos.
          final (mine: mineVisible, rest: bankVisible) = splitMine(visible);
          final mineTotal = habits.where((h) => h.isMine).length;
          final areas = _filter == null
              ? [
                  for (final area in HabitArea.values)
                    if (bankVisible.any((h) => h.area == area)) area,
                ]
              : <HabitArea>[_filter!];

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
            children: [
              const Text('ALL MICROHABITS', style: AppTypography.sectionLabel),
              const SizedBox(height: 4),
              Text(
                '${habits.length} small gestures'
                '${mineTotal > 0 ? ' · $mineTotal ${mineTotal == 1 ? 'mío' : 'míos'}' : ''}'
                ' · Aura picks for you each day',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Busca — agua, respirar, pareja…',
                  hintStyle: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB9AFC2),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Color(0xFFB9AFC2),
                  ),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFFB9AFC2),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(
                      color: Color(0xFFF0C3D3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _areaChip(null, 'Todas'),
                    for (final area in HabitArea.values)
                      _areaChip(area, area.label),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Crear el tuyo, siempre a mano (H1).
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.go(AppRoutes.habitCreate),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBFD),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE2A9BF),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '＋ Crear tu microhábito',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty && _query.trim().isNotEmpty)
                // El vacío invita, no frustra (H1).
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No encontré ninguno así.\n¿Lo creas tú? '
                    'El botón de arriba te espera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              // LOS TUYOS, siempre arriba: confirmación visual inmediata
              // al volver de crear, sin tener que buscar.
              if (mineVisible.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE3EC),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.star_border,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Míos',
                      style: TextStyle(
                        fontFamily: AppTypography.serif,
                        fontStyle: FontStyle.italic,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final habit in mineVisible)
                  _HabitRow(habit: habit, style: _areaStyle[habit.area]!),
                const SizedBox(height: 14),
              ],
              for (final area in areas) ...[
                _AreaHeader(style: _areaStyle[area]!),
                const SizedBox(height: 8),
                for (final habit in bankVisible.where((h) => h.area == area))
                  _HabitRow(habit: habit, style: _areaStyle[area]!),
                const SizedBox(height: 14),
              ],
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.profile),
                  child: const Text(
                    '← Back',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _areaChip(HabitArea? area, String label) {
    final on = _filter == area;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => setState(() => _filter = area),
        showCheckmark: false,
        selectedColor: const Color(0xFFFCE3EC),
        backgroundColor: AppColors.surface,
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: on ? FontWeight.w700 : FontWeight.w400,
          color: on ? AppColors.primary : AppColors.textSecondary,
        ),
        side: BorderSide(
          color: on ? const Color(0xFFF0C3D3) : AppColors.border,
          width: 1.5,
        ),
      ),
    );
  }
}

class _AreaHeader extends StatelessWidget {
  const _AreaHeader({required this.style});

  final _AreaStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(style.icon, size: 16, color: style.fg),
        ),
        const SizedBox(width: 10),
        Text(
          style.name,
          style: const TextStyle(
            fontFamily: AppTypography.serif,
            fontStyle: FontStyle.italic,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.habit, required this.style});

  final CatalogHabit habit;
  final _AreaStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono propio del hábito, teñido con el color del área (maquetado).
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: style.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              habitIconData(habit.icon, habit.area),
              size: 18,
              color: style.fg,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (habit.auraCopy.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    habit.auraCopy,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${habit.durationMinutes} min',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: style.fg,
                ),
              ),
              // Badges de Hábitos v2: "tuyo" (privado o publicado) y
              // "tuyo · en revisión" (pidió compartirlo).
              if (habit.isMine) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: habit.visibility == 'pending_review'
                        ? const Color(0xFFFFF6E8)
                        : const Color(0xFFFCE3EC),
                    borderRadius: BorderRadius.circular(50),
                    border: habit.visibility == 'pending_review'
                        ? Border.all(color: const Color(0xFFF2DFC2))
                        : null,
                  ),
                  child: Text(
                    habit.visibility == 'pending_review'
                        ? 'mío · en revisión'
                        : 'mío',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: habit.visibility == 'pending_review'
                          ? const Color(0xFFB07A2D)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
