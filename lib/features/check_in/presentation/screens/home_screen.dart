import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../../../constellation/presentation/providers/constellation_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../session/presentation/providers/session_controller.dart';
import '../../domain/entities/check_in_result.dart';
import '../providers/areas_presence_provider.dart';
import '../providers/daily_flow_controller.dart';
import '../widgets/areas_presence_card.dart';
import '../widgets/energy_visuals.dart';
import '../widgets/habit_card.dart';
import '../widgets/swap_habit_sheet.dart';
import '../../../session/presentation/providers/session_draft_provider.dart';

/// Home (maquetado · tab "home"): saludo, cómo estás hoy, la constelación en
/// curso y "Tu día en 3 minutos". Nunca compara con ayer ni cuenta ausencias.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _closing = false;

  Future<void> _closeDay(Recommendation recommendation) async {
    final draft = ref.read(sessionDraftProvider);
    final habit1 = draft[recommendation.habit1.id];
    if (habit1 == null || _closing) return;
    setState(() => _closing = true);
    final ok = await ref
        .read(sessionControllerProvider.notifier)
        .closeDay(
          habit1Result: habit1,
          habit2Result: recommendation.habit2 == null
              ? null
              : draft[recommendation.habit2!.id],
        );
    if (!mounted) return;
    setState(() => _closing = false);
    if (ok) {
      ref.read(sessionDraftProvider.notifier).clear();
      ref.invalidate(currentConstellationProvider);
      ref.invalidate(todaySessionProvider);
      ref.invalidate(areasPresenceProvider); // el cierre puede encender áreas
      context.go(AppRoutes.dayClose);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('No pudimos cerrar el día. Inténtalo en un momento.'),
          ),
        );
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyFlowProvider);
    final profile = ref.watch(profileProvider);
    final constellation = ref.watch(currentConstellationProvider);
    // El cierre de hoy según el SERVIDOR (sobrevive reinicios) o el de esta
    // sesión de app: con él se pinta la opción elegida tachada.
    final todaySession =
        ref.watch(todaySessionProvider).valueOrNull ??
        ref.watch(sessionControllerProvider).valueOrNull?.session;
    final closed = todaySession != null;
    final serif = Theme.of(context).textTheme.headlineMedium!;

    final result = daily.valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(dailyFlowProvider.notifier).refresh();
            ref.invalidate(currentConstellationProvider);
            ref.invalidate(areasPresenceProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(
                '$_greeting, ${profile.valueOrNull?.name ?? '…'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              if (result != null)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Hoy estás ', style: serif),
                      TextSpan(
                        text: result.checkIn.emotionalState.label.toLowerCase(),
                        style: serif.copyWith(color: AppColors.secondary),
                      ),
                    ],
                  ),
                )
              else
                Text('Tu día empieza contigo', style: serif),
              const SizedBox(height: 14),
              // Hero del maquetado: tras el check-in cambia a la ilustración
              // del estado elegido; antes, la imagen genérica del Home.
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: result != null
                    ? Image.asset(
                        result.checkIn.emotionalState.recoHeroAsset,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        'assets/images/home.png',
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0FA),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    switch (constellation.valueOrNull) {
                      null => 'Tu cielo se abre con tu primer día',
                      final c =>
                        'Constelación ${c.name} · ${c.starsEarned} '
                            '${c.starsEarned == 1 ? 'estrella' : 'estrellas'}',
                    },
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // "Tu cuidado, por áreas": presencia encendida del ciclo
              // (mockup aprobado — sin %, sin metas, sin reproches).
              const AreasPresenceCard(),
              const SizedBox(height: 22),
              if (daily.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (result == null)
                _CheckInInvite(onTap: () => context.go(AppRoutes.checkIn))
              else ...[
                const Text(
                  'TU DÍA EN 3 MINUTOS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                // Día cerrado: tarjeta del maquetado (home-closed-card) con
                // las estrellas de hoy y el CTA a la constelación.
                if (closed) ...[
                  _DayClosedCard(
                    stars: todaySession.starsEarned,
                    constellationName: constellation.valueOrNull?.name ?? '',
                  ),
                  const SizedBox(height: 10),
                ],
                for (final (index, habit)
                    in result.recommendation.habits.indexed) ...[
                  HabitCard(
                    habit: habit,
                    result: ref.watch(sessionDraftProvider)[habit.id],
                    // Día cerrado: la opción elegida se pinta TACHADA
                    // (todaySession null = día abierto -> null).
                    closedResult: index == 0
                        ? todaySession?.habit1Result
                        : todaySession?.habit2Result,
                    // ⇄ solo con el día abierto y la tarjeta sin marcar:
                    // sustituye, nunca añade (el número lo fijó el motor).
                    onSwap:
                        closed ||
                            ref
                                .watch(sessionDraftProvider)
                                .containsKey(habit.id)
                        ? null
                        : () => showSwapHabitSheet(
                            context,
                            slot: index + 1,
                            current: habit,
                            other: result.recommendation.habits
                                .where((h) => h.id != habit.id)
                                .firstOrNull,
                            state: result.checkIn.emotionalState,
                          ),
                    onMark: (value) => ref
                        .read(sessionDraftProvider.notifier)
                        .setResult(habit.id, value),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                if (!closed)
                  SoftPrimaryButton(
                    label: 'Cerrar mi día',
                    isLoading: _closing,
                    onPressed:
                        ref
                            .watch(sessionDraftProvider)
                            .containsKey(result.recommendation.habit1.id)
                        ? () => _closeDay(result.recommendation)
                        : null,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Invitación al check-in cuando el día aún no empezó (una puerta, no un
/// reproche: sin culpa ni urgencia).
class _CheckInInvite extends StatelessWidget {
  const _CheckInInvite({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Cuánta energía hay hoy?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cuéntale a Aura y ella da forma a tu día.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SoftPrimaryButton(label: 'Hacer mi check-in', onPressed: onTap),
        ],
      ),
    );
  }
}

/// Tarjeta del día cerrado (home-closed-card del maquetado): degradado
/// carmesí sobre la imagen del Home, estrella en círculo translúcido, las
/// estrellas de HOY y el CTA a la constelación. Solo dice cuánto sumó —
/// jamás evalúa el día (GUARD_TONE).
class _DayClosedCard extends StatelessWidget {
  const _DayClosedCard({required this.stars, required this.constellationName});

  final int stars;
  final String constellationName;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/home.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.4),
            ),
          ),
          // Velo del maquetado: linear-gradient(160deg, C01448 .82, 961042 .92).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFC01448).withValues(alpha: 0.82),
                    const Color(0xFF961042).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          // Ancho completo: sin esto la Column se encoge al texto más ancho
          // y el bloque queda descentrado cuando el nombre es corto.
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    child: const Center(
                      child: Text(
                        '✦',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You closed your day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rest now — see you tomorrow.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '+$stars ${stars == 1 ? 'star' : 'stars'}'
                    '${constellationName.isEmpty ? '' : ' · $constellationName constellation'}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => context.go(AppRoutes.constellation),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Text(
                          'See my constellation →',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
