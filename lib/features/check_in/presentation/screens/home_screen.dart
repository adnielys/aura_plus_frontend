import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../../../constellation/presentation/providers/constellation_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../session/presentation/providers/session_controller.dart';
import '../../domain/entities/check_in_result.dart';
import '../providers/daily_flow_controller.dart';
import '../widgets/energy_visuals.dart';
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
    final ok = await ref.read(sessionControllerProvider.notifier).closeDay(
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
      context.go(AppRoutes.dayClose);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('No pudimos cerrar el día. Inténtalo en un momento.'),
        ));
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
    final closed = ref.watch(sessionControllerProvider).valueOrNull != null;
    final serif = Theme.of(context).textTheme.headlineMedium!;

    final result = daily.valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(dailyFlowProvider.notifier).refresh();
            ref.invalidate(currentConstellationProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(
                '$_greeting, ${profile.valueOrNull?.name ?? '…'}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              if (result != null)
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Hoy estás ', style: serif),
                    TextSpan(
                      text: result.checkIn.emotionalState.label.toLowerCase(),
                      style: serif.copyWith(color: AppColors.secondary),
                    ),
                  ]),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0FA),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    switch (constellation.valueOrNull) {
                      null => 'Tu cielo se abre con tu primer día',
                      final c => 'Constelación ${c.name} · ${c.starsEarned} '
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
                for (final habit in result.recommendation.habits) ...[
                  _RoutineCard(
                    habit: habit,
                    result: ref.watch(sessionDraftProvider)[habit.id],
                    enabled: !closed,
                    onChanged: (value) => ref
                        .read(sessionDraftProvider.notifier)
                        .setResult(habit.id, value),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                if (closed)
                  const Center(
                    child: Text(
                      'Tu día quedó guardado. El cielo lo conserva.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  )
                else
                  SoftPrimaryButton(
                    label: 'Cerrar mi día',
                    isLoading: _closing,
                    onPressed: ref
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

/// Tarjeta de rutina: hábito + selector del resultado. "No fue posible" es una
/// respuesta válida que también suma.
class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.habit,
    required this.result,
    required this.enabled,
    required this.onChanged,
  });

  final Habit habit;
  final HabitResult? result;
  final bool enabled;
  final ValueChanged<HabitResult> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${habit.area.label} · ${habit.durationMinutes} min',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: [
              for (final option in HabitResult.values)
                ChoiceChip(
                  label:
                      Text(option.label, style: const TextStyle(fontSize: 12)),
                  selected: result == option,
                  selectedColor: const Color(0xFFFFF0F4),
                  onSelected: enabled ? (_) => onChanged(option) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
