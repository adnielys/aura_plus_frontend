import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/habit_icons.dart';
import '../../../profile/presentation/providers/habits_catalog_provider.dart';
import '../../../profile/presentation/screens/habit_create_screen.dart';
import '../../domain/entities/check_in_result.dart';
import '../providers/daily_flow_controller.dart';

/// Minutos máximos que ofrece cada energía (espejo del ENERGY_PLAN del
/// maquetado; la validación REAL es del servidor — esto solo pinta los
/// bloqueos honestos del selector).
const Map<EmotionalState, int> _maxMinutesByState = {
  EmotionalState.energy: 10,
  EmotionalState.tranquil: 8,
  EmotionalState.scattered: 6,
  EmotionalState.exhausted: 5,
  EmotionalState.hard: 2,
};

/// Colores por área (mismos tonos que las HabitCards).
const Map<HabitArea, (Color bg, Color fg, Color iconBg, String name)>
_areaStyle = {
  HabitArea.self: (
    Color(0xFFFFE3EE),
    Color(0xFFC01448),
    Color(0xFFFFF0F4),
    'Me',
  ),
  HabitArea.family: (
    Color(0xFFFCE9D6),
    Color(0xFFE0894A),
    Color(0xFFFFF6EE),
    'Family',
  ),
  HabitArea.relationships: (
    Color(0xFFECE1FB),
    Color(0xFF9B6FD4),
    Color(0xFFF6F0FF),
    'Relationships',
  ),
  HabitArea.work: (
    Color(0xFFDCE9F6),
    Color(0xFF3F7CB0),
    Color(0xFFEEF5FC),
    'Work',
  ),
};

/// Abre el banco en modo SUSTITUCIÓN: reemplaza el hábito de `slot` por otro.
/// Cambia CUÁL, nunca CUÁNTOS (el número lo fijó el motor con su energía).
Future<void> showSwapHabitSheet(
  BuildContext context, {
  required int slot,
  required Habit current,
  required Habit? other,
  required EmotionalState state,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _SwapSheet(
        slot: slot,
        current: current,
        other: other,
        state: state,
      ),
    ),
  );
}

class _SwapSheet extends ConsumerStatefulWidget {
  const _SwapSheet({
    required this.slot,
    required this.current,
    required this.other,
    required this.state,
  });

  final int slot;
  final Habit current;
  final Habit? other;
  final EmotionalState state;

  @override
  ConsumerState<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<_SwapSheet> {
  String? _selectedId;
  bool _submitting = false;

  /// Motivo del bloqueo (null = elegible). Sin culpa: dice por qué, no "no".
  String? _lockReason(CatalogHabit habit) {
    if (habit.id == widget.current.id) return 'tu gesto actual';
    if (widget.other != null && habit.area == widget.other!.area) {
      final name = _areaStyle[habit.area]!.$4;
      return 'tu otro gesto ya es de $name — cuidamos tu balance';
    }
    final cap = _maxMinutesByState[widget.state]!;
    if (habit.durationMinutes > cap) return 'no cabe en el tiempo de hoy';
    return null;
  }

  Future<void> _replace() async {
    final habitId = _selectedId;
    if (habitId == null || _submitting) return;
    setState(() => _submitting = true);
    final error = await ref
        .read(dailyFlowProvider.notifier)
        .swapHabit(slot: widget.slot, habitId: habitId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      // El servidor manda (valida energía/balance/tiempo); su mensaje es sin culpa.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(habitsCatalogProvider);
    final gestures = widget.other == null ? 1 : 2;

    return Column(
      children: [
        const SizedBox(height: 18),
        const Text('YOUR MICROHABITS', style: AppTypography.eyebrow),
        const SizedBox(height: 2),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Swap ',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium!.copyWith(fontSize: 24),
              ),
              TextSpan(
                text: 'this one',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tu día mantiene $gestures ${gestures == 1 ? 'gesto' : 'gestos'} · '
          'eliges 1 sustituto',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        // Tarjeta fija: qué se está sustituyendo.
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Sustituyendo: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text:
                      '${widget.current.title} · '
                      '${widget.current.durationMinutes} min',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: catalog.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(habitsCatalogProvider),
                child: const Text('Reintentar'),
              ),
            ),
            data: (habits) {
              // Los suyos SIEMPRE primero (Hábitos v2): lo que ella creó
              // jamás queda enterrado entre 120 gestos de la casa.
              final (mine: mineHabits, rest: bankHabits) = splitMine(habits);
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  if (mineHabits.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        'Míos',
                        style: TextStyle(
                          fontFamily: AppTypography.serif,
                          fontStyle: FontStyle.italic,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    for (final habit in mineHabits)
                      _PickRow(
                        habit: habit,
                        lockReason: _lockReason(habit),
                        selected: _selectedId == habit.id,
                        onTap: () => setState(
                          () => _selectedId = _selectedId == habit.id
                              ? null
                              : habit.id,
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                  for (final area in HabitArea.values) ...[
                    _AreaHeader(area: area),
                    for (final habit in bankHabits.where((h) => h.area == area))
                      _PickRow(
                        habit: habit,
                        lockReason: _lockReason(habit),
                        selected: _selectedId == habit.id,
                        onTap: () => setState(
                          () => _selectedId = _selectedId == habit.id
                              ? null
                              : habit.id,
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                  // Hábitos v2 (H4): crear uno nuevo PARA ESTE HUECO — área
                  // fija (la del gesto que sale) y duración limitada al
                  // presupuesto de hoy. Al guardarlo, sustituye directo.
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      final HabitCreateArgs args = (
                        fixedArea: widget.current.area,
                        maxMinutes: _maxMinutesByState[widget.state]!,
                        swapSlot: widget.slot,
                      );
                      Navigator.of(context).pop();
                      context.go(AppRoutes.habitCreate, extra: args);
                    },
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
                          '＋ Crear uno nuevo para este hueco',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              );
            },
          ),
        ),
        // Pie fijo: contador + CTA + regla.
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.surfaceTint)),
          ),
          child: Column(
            children: [
              Text(
                '${_selectedId == null ? 0 : 1} of 1 selected',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _selectedId == null
                        ? null
                        : const LinearGradient(
                            colors: [
                              AppColors.entryAccent,
                              AppColors.entryAccentDark,
                            ],
                          ),
                    color: _selectedId == null ? const Color(0xFFF2A9C4) : null,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: _selectedId == null || _submitting
                          ? null
                          : _replace,
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Replace habit   ✦',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No añade un gesto más: sustituye este.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AreaHeader extends StatelessWidget {
  const _AreaHeader({required this.area});

  final HabitArea area;

  @override
  Widget build(BuildContext context) {
    final (_, fg, iconBg, name) = _areaStyle[area]!;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(habitIconData(null, area), size: 14, color: fg),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontFamily: AppTypography.serif,
              fontStyle: FontStyle.italic,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.habit,
    required this.lockReason,
    required this.selected,
    required this.onTap,
  });

  final CatalogHabit habit;
  final String? lockReason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (_, fg, iconBg, _) = _areaStyle[habit.area]!;
    final locked = lockReason != null;

    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: locked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    habitIconData(habit.icon, habit.area),
                    size: 16,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${habit.durationMinutes} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (locked)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: Text(
                      lockReason!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Center(
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
