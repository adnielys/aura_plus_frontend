import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/constellation.dart';
import '../providers/constellation_provider.dart';
import '../providers/cycle_closing_provider.dart';
import '../widgets/constellation_visuals.dart';

/// Constelación del ciclo (maquetado · tab "constelacion"): cielo ROSADO
/// claro con la ilustración, pill con el nombre en serif itálica, tarjeta
/// "This cycle" con tiles de estadísticas y acceso a "My galaxy".
/// GUARD_TONE_04: solo cuánto llevas — jamás cuánto falta ni comparaciones.
/// Al entrar dispara la ceremonia de cierre si hay una pendiente (SPEC V2 §1).
class ConstellationScreen extends ConsumerStatefulWidget {
  const ConstellationScreen({super.key});

  @override
  ConsumerState<ConstellationScreen> createState() =>
      _ConstellationScreenState();
}

class _ConstellationScreenState extends ConsumerState<ConstellationScreen> {
  @override
  void initState() {
    super.initState();
    // Disparo de la ceremonia: nunca bloqueante y en silencio ante error.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final closing = await ref.read(cycleClosingProvider.future);
      if (!mounted || closing == null) return;
      if (ref.read(cycleClosePostponedProvider)) return; // "Ahora no" (sesión)
      if (!mounted) return;
      context.push(AppRoutes.cycleClose, extra: closing);
    });
  }

  @override
  Widget build(BuildContext context) {
    final constellation = ref.watch(currentConstellationProvider);

    return Scaffold(
      body: constellation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No pudimos abrir tu cielo.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => ref.invalidate(currentConstellationProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (value) => value == null
            ? const Center(
                child: Text(
                  'Tu cielo se abre con tu primer día.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : _Body(constellation: value),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.constellation});

  final Constellation constellation;

  @override
  Widget build(BuildContext context) {
    final stars = constellation.starsEarned;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Sky(constellation: constellation),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('THIS CYCLE', style: AppTypography.sectionLabel),
              const SizedBox(height: 12),
              // Tarjeta del ciclo (maquetado): frase serif itálica con el
              // valor en carmesí + tiles de estadísticas.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'This cycle you gave yourself ',
                          style: _serifItalic(context),
                        ),
                        TextSpan(
                          text: '$stars ${stars == 1 ? 'star' : 'stars'}',
                          style: _serifItalic(context).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                        TextSpan(
                          text: ' for you.',
                          style: _serifItalic(context),
                        ),
                      ]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            value: '$stars',
                            label: 'stars gathered',
                          ),
                        ),
                        // Presencia: días con check-in, solo acumula
                        // (GUARD_TONE_03/04: jamás cuántos faltan).
                        if (constellation.daysPresent != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              value: '${constellation.daysPresent}',
                              label: constellation.daysPresent == 1
                                  ? 'day of presence'
                                  : 'days of presence',
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            value: '${constellation.cycleNumber}',
                            label: constellation.cycleNumber == 1
                                ? 'first cycle'
                                : 'cycles walked',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Every star is permanent — your sky keeps them.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Acceso a la galaxia (maquetado · row "My galaxy · Premium").
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go(AppRoutes.galaxy),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0F4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.blur_circular,
                            size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'My galaxy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCE3EC),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Your past constellations',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 20, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _serifItalic(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 19,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            height: 1.4,
          );
}

/// Cielo ROSADO del maquetado: halo radial suave, la ilustración de la
/// constelación del ciclo, pill con el nombre y "By Aura Plus".
class _Sky extends StatelessWidget {
  const _Sky({required this.constellation});

  final Constellation constellation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 26, bottom: 20),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.4),
          radius: 1.1,
          colors: [Color(0xFFF9DCE7), Color(0xFFFBEAF0), Color(0xFFFAFAFA)],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Column(
        children: [
          Image.asset(
            constellation.imageAsset,
            height: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 6),
          // Pill con el nombre (serif itálica carmesí, borde carmesí).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Text(
              '${constellation.name} Constellation',
              style: const TextStyle(
                fontFamily: AppTypography.serif,
                fontStyle: FontStyle.italic,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'By Aura Plus',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tile de estadística (maquetado): fondo lila, número serif carmesí.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTypography.serif,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
