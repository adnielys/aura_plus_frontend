import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../providers/history_provider.dart';

const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

/// Colores por estado emocional (los tonos que ya existen — "Al límite" en
/// azul profundo, jamás rojo de error, UX_09).
EmotionalStateColors stateColors(EmotionalState state) => switch (state) {
      EmotionalState.energy => EmotionalStateColors.energy,
      EmotionalState.tranquil => EmotionalStateColors.tranquil,
      EmotionalState.scattered => EmotionalStateColors.scattered,
      EmotionalState.exhausted => EmotionalStateColors.exhausted,
      EmotionalState.hard => EmotionalStateColors.hard,
    };

/// Historia v2 · V1 (lista viva): SOLO los días en que ella estuvo, con el
/// color de su estado y lo que registró. El silencio no aparece ni se cuenta
/// — nunca huecos, rachas rotas ni días perdidos (UX_06/07, GUARD_TONE_02/03).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.invalidate(historyProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

    return Scaffold(
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(historyProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (days) {
          final (thisWeek: thisWeek, earlier: earlier) =
              groupHistory(days, DateTime.now());
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
            children: [
              const Text('TU HISTORIA · ÚLTIMOS 28 DÍAS',
                  style: AppTypography.sectionLabel),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: 'Lo que construiste, ', style: serif),
                  TextSpan(
                    text: 'día a día.',
                    style: serif.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.primary),
                  ),
                ]),
              ),
              const SizedBox(height: 4),
              Text(
                days.isEmpty
                    ? 'Tu historia empieza con tu primer check-in.'
                    : '${days.length} ${days.length == 1 ? 'día' : 'días'} de '
                        'presencia · el silencio nunca resta.',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              if (thisWeek.isNotEmpty) ...[
                const _WeekLabel('ESTA SEMANA'),
                for (final day in thisWeek) _DayRow(day: day),
              ],
              if (earlier.isNotEmpty) ...[
                const SizedBox(height: 6),
                const _WeekLabel('ANTES'),
                for (final day in earlier) _DayRow(day: day),
              ],
              if (days.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Cada día guarda su historia completa —\ntócalo para volver a él.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.profile),
                  child: const Text(
                    '← Volver',
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
}

class _WeekLabel extends StatelessWidget {
  const _WeekLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0xFFB9AFC2),
        ),
      ),
    );
  }
}

/// Fila de un día con presencia: fecha, cómo llegó (con su color) y lo que
/// registró. Tocar el día abre su memoria completa (V2).
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});

  final HistoryDay day;

  @override
  Widget build(BuildContext context) {
    final date = day.date;
    final colors = day.state == null ? null : stateColors(day.state!);
    final accent = colors?.accent ?? AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(AppRoutes.historyDay, extra: date),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Row(
            children: [
              // Acento del estado: barrita interna (un borde izquierdo grueso
              // no convive con esquinas redondeadas en Flutter).
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _weekdays[date.weekday - 1],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontFamily: AppTypography.serif,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.state?.label ?? 'Presente',
                      style: TextStyle(
                        fontFamily: AppTypography.serif,
                        fontStyle: FontStyle.italic,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    Text(
                      day.hadSession
                          ? '${day.gesturesCount} '
                              '${day.gesturesCount == 1 ? 'gesto registrado' : 'gestos registrados'}'
                          : 'check-in · el registro ya fue el logro',
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
        ),
      ),
    );
  }
}
