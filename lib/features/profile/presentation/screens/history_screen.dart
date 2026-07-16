import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/history_provider.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Historial (fila "History" del perfil): SOLO los días en que ella estuvo.
/// El silencio no aparece ni se cuenta — nunca se pintan huecos, rachas rotas
/// ni días perdidos (UX_06/07, GUARD_TONE_02/03).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(historyProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (days) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
          children: [
            const Text('YOUR LAST 28 DAYS', style: AppTypography.sectionLabel),
            const SizedBox(height: 4),
            Text(
              days.isEmpty
                  ? 'Your story starts with your first check-in.'
                  : '${days.length} ${days.length == 1 ? 'day' : 'days'} of '
                      'presence · silence never counts against you',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final day in days) _DayRow(day: day),
            const SizedBox(height: 4),
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

/// Fila de un día con presencia: fecha, cómo estaba y lo que sumó ese día.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final HistoryDay day;

  @override
  Widget build(BuildContext context) {
    final date = day.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Fecha compacta (día de semana + día/mes).
          SizedBox(
            width: 64,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdays[date.weekday - 1],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${date.day} ${_months[date.month - 1]}',
                  style: const TextStyle(
                    fontFamily: AppTypography.serif,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              day.state?.label ?? 'Presente',
              style: const TextStyle(
                fontFamily: AppTypography.serif,
                fontStyle: FontStyle.italic,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Lo que sumó ese día: estrellas del cierre o el check-in mismo
          // (que también es logro).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: day.hadSession
                  ? const Color(0xFFFCE3EC)
                  : AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              day.hadSession ? '+${day.starsEarned} ✦' : 'check-in',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: day.hadSession
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
