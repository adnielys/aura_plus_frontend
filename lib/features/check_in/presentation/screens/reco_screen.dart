import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/enums.dart';
import '../../../constellation/presentation/providers/constellation_provider.dart';
import '../../../session/presentation/providers/session_controller.dart';
import '../../../session/presentation/providers/session_draft_provider.dart';
import '../../domain/entities/check_in_result.dart';
import '../providers/daily_flow_controller.dart';
import '../widgets/energy_visuals.dart';

/// Recomendación del día (maquetado · pantalla "reco"): título, hero e
/// indicaciones según la ENERGÍA elegida; tarjetas de hábito con Done /
/// Not today; y cierre del día desde aquí. El texto emocional viene del
/// SERVIDOR; esta pantalla solo lo pinta.
class RecoScreen extends ConsumerStatefulWidget {
  const RecoScreen({super.key});

  @override
  ConsumerState<RecoScreen> createState() => _RecoScreenState();
}

class _RecoScreenState extends ConsumerState<RecoScreen> {
  bool _closing = false;

  /// Título por estado (RECO_COPY del maquetado): palabra clave en carmesí.
  static const _title = {
    EmotionalState.energy: ('Today, a little ', 'more', ''),
    EmotionalState.tranquil: ('Today, just ', 'this', ''),
    EmotionalState.scattered: ('Keep it ', 'light', ' today'),
    EmotionalState.exhausted: ('Just one ', 'gentle', ' thing'),
    EmotionalState.hard: ('Today, only ', 'rest', ''),
  };

  Future<void> _closeDay(Recommendation recommendation) async {
    if (_closing) return;
    setState(() => _closing = true);
    final draft = ref.read(sessionDraftProvider);
    // Sin marcar cuenta como "no fue posible": también suma (filosofía).
    final ok = await ref.read(sessionControllerProvider.notifier).closeDay(
          habit1Result:
              draft[recommendation.habit1.id] ?? HabitResult.notPossible,
          habit2Result: recommendation.habit2 == null
              ? null
              : draft[recommendation.habit2!.id] ?? HabitResult.notPossible,
        );
    if (!mounted) return;
    setState(() => _closing = false);
    if (ok) {
      ref.read(sessionDraftProvider.notifier).clear();
      ref.invalidate(currentConstellationProvider);
      context.go(AppRoutes.dayClose);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('No pudimos cerrar el día. Inténtalo en un momento.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyFlowProvider);
    final result = daily.valueOrNull;

    if (result == null) {
      // Sin resultado (p. ej. deep-link sin check-in): volver al flujo normal.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final state = result.checkIn.emotionalState;
    final habits = result.recommendation.habits;
    final draft = ref.watch(sessionDraftProvider);
    final done =
        habits.where((h) => draft[h.id] == HabitResult.done).length;
    final serif = Theme.of(context).textTheme.headlineMedium!;
    final (pre, emphasis, post) = _title[state]!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
                children: [
                  // Título por energía, palabra clave en carmesí itálica.
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: pre, style: serif),
                      TextSpan(
                        text: emphasis,
                        style: serif.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(text: post, style: serif),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    done >= habits.length
                        ? 'All done — beautiful'
                        : '$done of ${habits.length} done',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  // Hero según la energía elegida (mircrohabitos/{estado}).
                  Center(
                    child: Image.asset(
                      state.recoHeroAsset,
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Pill con contorno carmesí (sub del maquetado).
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        habits.length == 1
                            ? 'One small gesture, just for you'
                            : 'Two small gestures, in ${habits.length} areas',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AuraMessage(text: result.messages.recommendation),
                  const SizedBox(height: 14),
                  for (final habit in habits) ...[
                    _HabitCard(
                      habit: habit,
                      result: draft[habit.id],
                      onMark: (value) => ref
                          .read(sessionDraftProvider.notifier)
                          .setResult(habit.id, value),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            // Footer del maquetado: enlace al Home + cerrar el día.
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Go to my Home',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFECEAEE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 13, color: Color(0xFF8B8692)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 2, 24, 20),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.entryAccent, AppColors.entryAccentDark],
                    ),
                    borderRadius: BorderRadius.circular(29),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.entryAccent.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(29),
                      onTap: _closing
                          ? null
                          : () => _closeDay(result.recommendation),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_closing)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          else
                            const Text(
                              'Close my day',
                              // continue-btn de la zona app: firme, w700.
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          const Positioned(
                            right: 24,
                            child: Text('✦',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
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

/// Mensaje de Aura del maquetado: burbuja con degradado nocturno, punto rosa
/// y el texto del SERVIDOR en serif itálica blanca.
class _AuraMessage extends StatelessWidget {
  const _AuraMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0820), Color(0xFF4A0828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              // aura-text del maquetado: serif itálica 13, blanco al 78%.
              style: TextStyle(
                fontFamily: 'Poltawski Nowy',
                fontStyle: FontStyle.italic,
                fontSize: 13.5,
                height: 1.55,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de hábito del maquetado: icono en cápsula del área, título, minutos,
/// pill del área a la derecha y la franja de confirmación Done | Not today.
class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.result,
    required this.onMark,
  });

  final Habit habit;
  final HabitResult? result;
  final ValueChanged<HabitResult> onMark;

  /// Colores e icono por área (AREA del maquetado).
  static const _areaStyle = {
    HabitArea.self: (Color(0xFFFFE3EE), Color(0xFFC01448), Color(0xFFFFF0F4),
        Icons.self_improvement),
    HabitArea.family: (Color(0xFFFCE9D6), Color(0xFFE0894A), Color(0xFFFFF6EE),
        Icons.auto_stories),
    HabitArea.relationships: (Color(0xFFECE1FB), Color(0xFF9B6FD4),
        Color(0xFFF6F0FF), Icons.favorite_border),
    HabitArea.work: (Color(0xFFDCE9F6), Color(0xFF3F7CB0), Color(0xFFEEF5FC),
        Icons.work_outline),
  };

  /// Etiqueta EN del área (zona reco del maquetado).
  static const _areaLabel = {
    HabitArea.self: 'Me',
    HabitArea.family: 'Family',
    HabitArea.relationships: 'Relationships',
    HabitArea.work: 'Work',
  };

  @override
  Widget build(BuildContext context) {
    final (tagBg, tagFg, iconBg, icon) = _areaStyle[habit.area]!;
    final isDone = result == HabitResult.done;
    final marked = result != null;

    // Métrica exacta del maquetado (micro-card): borde --border 1px, radio 18,
    // icono 38/r12, título 14 w700, meta 11. Al marcar: la franja desaparece,
    // el meta registra la elección y "Done" atenúa la tarjeta con tachado.
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDone ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 11),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: tagFg),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          marked
                              ? (isDone ? 'Completed' : 'Not today · logged')
                              : '${habit.durationMinutes} min',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                marked ? FontWeight.w600 : FontWeight.w400,
                            color: marked && !isDone
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      _areaLabel[habit.area]!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tagFg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Franja de confirmación (confirm-strip): desaparece al marcar.
            if (!marked)
              Container(
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: AppColors.surfaceTint)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(18)),
                        onTap: () => onMark(HabitResult.done),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                        width: 1, height: 42, color: AppColors.surfaceTint),
                    Expanded(
                      child: InkWell(
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(18)),
                        onTap: () => onMark(HabitResult.notPossible),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          child: const Text(
                            'Not today',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
