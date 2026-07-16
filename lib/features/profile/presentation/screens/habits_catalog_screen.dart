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
/// motor; aquí ella solo hojea qué gestos existen.
class HabitsCatalogScreen extends ConsumerWidget {
  const HabitsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        data: (habits) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
          children: [
            const Text('ALL MICROHABITS', style: AppTypography.sectionLabel),
            const SizedBox(height: 4),
            Text(
              '${habits.length} small gestures · Aura picks for you each day',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final area in HabitArea.values) ...[
              _AreaHeader(style: _areaStyle[area]!),
              const SizedBox(height: 8),
              for (final habit in habits.where((h) => h.area == area))
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
          decoration:
              BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(9)),
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
          Text(
            '${habit.durationMinutes} min',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: style.fg,
            ),
          ),
        ],
      ),
    );
  }
}
