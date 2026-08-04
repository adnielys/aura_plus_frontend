import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/section_hero.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../providers/history_provider.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
  // Historia total (Q3): páginas extra cargadas al hacer scroll hacia atrás.
  final List<HistoryDay> _extra = [];
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _exporting = false;

  /// Exportar su historia (jul 2026): el servidor compone el diario .txt con
  /// los textos EXACTOS persistidos; aquí solo se abre la hoja de compartir
  /// del sistema (guardarlo, enviárselo, imprimirlo — ella decide).
  Future<void> _exportStory() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final response = await ref.read(dioProvider).get<String>(
            '/session/export',
            options: Options(responseType: ResponseType.plain),
          );
      final text = response.data ?? '';
      if (text.isEmpty) throw Exception('empty');
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'My story — Aura+'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content:
                Text("We couldn't prepare your story. Try again in a moment."),
          ));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _extra.clear();
          _hasMore = true;
        });
        ref.invalidate(historyProvider);
      }
    });
  }

  Future<void> _loadMore(List<HistoryDay> loaded) async {
    if (_loadingMore || !_hasMore || loaded.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await fetchHistoryPage(
        ref.read(dioProvider),
        before: loaded.last.date,
      );
      if (!mounted) return;
      setState(() {
        _extra.addAll(page);
        _hasMore = page.length >= historyPageSize;
      });
    } catch (_) {
      // Silencioso: el siguiente scroll reintenta (la historia nunca regaña).
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
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
      backgroundColor: AppColors.background,
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(historyProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (firstPage) {
          final days = [...firstPage, ..._extra];
          final sections = groupHistoryMonths(days, DateTime.now());
          // Con solo la primera página, "hay más" si vino llena; con páginas
          // extra manda lo que dijo la última carga.
          final more =
              _extra.isEmpty ? firstPage.length >= historyPageSize : _hasMore;
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (more &&
                  notification.metrics.pixels >
                      notification.metrics.maxScrollExtent - 300) {
                _loadMore(days);
              }
              return false;
            },
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SectionHeader(
                  asset: 'assets/images/care/profile_hero.png',
                  eyebrow: 'YOUR STORY',
                  title: [
                    const TextSpan(text: 'Everything you built '),
                    TextSpan(
                      text: 'stays yours.',
                      style: serif.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary),
                    ),
                  ],
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go(AppRoutes.profile),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                  days.isEmpty
                      ? 'Your story starts with your first check-in.'
                      : '${days.length} ${days.length == 1 ? 'day' : 'days'} of '
                          'presence · silence never counts against you.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                for (final section in sections) ...[
                  _WeekLabel(section.label),
                  for (final day in section.days) _DayRow(day: day),
                  const SizedBox(height: 6),
                ],
                if (_loadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                        child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )),
                  ),
                if (days.isNotEmpty && !more) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Your whole story stays with you —\nas far back as your first day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
                if (days.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  // Exportar (jul 2026): su memoria es SUYA — se la lleva
                  // cuando quiera, como un diario.
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _exporting ? null : _exportStory,
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
                      child: Center(
                        child: _exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Text(
                                'Export my story ✦',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
                    ],
                  ),
                ),
              ],
            ),
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
                      day.state?.label ?? 'Present',
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
                              '${day.gesturesCount == 1 ? 'gesture logged' : 'gestures logged'}'
                          : 'check-in · logging it was already the win',
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
                      ? AppColors.selectedRose
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
