import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/utils/dates.dart';
import '../../../../shared/widgets/habit_icons.dart';
import '../providers/area_gestures_provider.dart';
import '../providers/history_provider.dart';
import 'history_screen.dart' show stateColors;

/// Colores por área para el icono del gesto (mismos tonos de siempre).
const Map<HabitArea, (Color bg, Color fg)> _areaTones = {
  HabitArea.self: (Color(0xFFFFF0F4), Color(0xFFC01448)),
  HabitArea.family: (Color(0xFFFFF6EE), Color(0xFFE0894A)),
  HabitArea.relationships: (Color(0xFFF6F0FF), Color(0xFF9B6FD4)),
  HabitArea.work: (Color(0xFFEEF5FC), Color(0xFF3F7CB0)),
};

/// Historia v2 · V2: la memoria completa de UN día. Estado con el que llegó,
/// gestos con su resultado, el mensaje EXACTO de esa noche y su palabra.
/// Nada editable: la memoria no se retoca.
class HistoryDayScreen extends ConsumerWidget {
  const HistoryDayScreen({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(historyDayProvider(date));

    return Scaffold(
      body: SafeArea(
        child: detail.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(historyDayProvider(date)),
              child: const Text('Reintentar'),
            ),
          ),
          data: (day) => ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.go(AppRoutes.history),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new,
                          size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text('Tu historia',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${spanishWeekday(day.date)} · ${spanishDate(day.date)}'
                    .toUpperCase(),
                style: AppTypography.sectionLabel,
              ),
              const SizedBox(height: 10),
              if (day.state != null) _StateHero(state: day.state!),
              if (day.gestures.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text('TUS GESTOS DE ESE DÍA',
                    style: AppTypography.sectionLabel),
                const SizedBox(height: 8),
                for (final gesture in day.gestures)
                  _GestureRow(gesture: gesture),
              ] else ...[
                const SizedBox(height: 14),
                const Text(
                  'Ese día llegaste y registraste cómo estabas — '
                  'eso también fue presencia.',
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.6,
                      color: AppColors.textSecondary),
                ),
              ],
              if (day.closingMessage != null &&
                  day.closingMessage!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LO QUE AURA TE DIJO ESA NOCHE',
                          style: AppTypography.sectionLabel),
                      const SizedBox(height: 6),
                      Text(
                        '"${day.closingMessage}"',
                        style: const TextStyle(
                          fontFamily: AppTypography.serif,
                          fontStyle: FontStyle.italic,
                          fontSize: 14.5,
                          height: 1.55,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (day.reflection != null && day.reflection!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TU PALABRA DE ESA NOCHE',
                          style: AppTypography.sectionLabel),
                      const SizedBox(height: 4),
                      Text(
                        '"${day.reflection}"',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: Color(0xFF4A4253),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (day.starsEarned > 0) ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE3EC),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      '+${day.starsEarned} ✦ ese día',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StateHero extends StatelessWidget {
  const _StateHero({required this.state});

  final EmotionalState state;

  @override
  Widget build(BuildContext context) {
    final colors = stateColors(state);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.label,
            style: TextStyle(
              fontFamily: AppTypography.serif,
              fontStyle: FontStyle.italic,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Ese día llegaste así — y aun así, estuviste.',
            style: TextStyle(
              fontSize: 10.5,
              color: colors.accent.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _GestureRow extends StatelessWidget {
  const _GestureRow({required this.gesture});

  final AreaGesture gesture;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _areaTones[gesture.area]!;
    final (chipBg, chipFg) = switch (gesture.result) {
      HabitResult.done => (const Color(0xFFFCE3EC), AppColors.primary),
      HabitResult.partial => (const Color(0xFFFFF6E8), const Color(0xFFB07A2D)),
      HabitResult.notPossible => (
          AppColors.surfaceTint,
          AppColors.textSecondary
        ),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(habitIconData(gesture.icon, gesture.area),
                size: 15, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              gesture.title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              gesture.result.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: chipFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
