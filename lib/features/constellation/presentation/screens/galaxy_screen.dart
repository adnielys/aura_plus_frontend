import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/constellation.dart';
import '../providers/constellation_provider.dart';
import '../widgets/constellation_visuals.dart';

/// Mi galaxia (maquetado · tab "galaxia"): cabecera nocturna + galería de
/// las constelaciones guardadas. Cada una es permanente: el cielo conserva
/// lo que ella construyó (GUARD_TONE: nunca se pierde progreso).
class GalaxyScreen extends ConsumerWidget {
  const GalaxyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final constellations = ref.watch(allConstellationsProvider);

    return Scaffold(
      body: constellations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(allConstellationsProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (all) => ListView(
          padding: EdgeInsets.zero,
          children: [
            // Cabecera nocturna (sky compacto del maquetado).
            Container(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2A0E3A), AppColors.closingBackground],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'My galaxy',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium!
                        .copyWith(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${all.length} ${all.length == 1 ? 'constellation' : 'constellations'} saved · Premium',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  for (final constellation in all) ...[
                    _ConstCard(constellation: constellation),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Every constellation is permanent. The sky keeps what you built.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.constellation),
                    child: const Text(
                      '← Back',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
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

/// Tarjeta de la galería (const-card light del maquetado).
class _ConstCard extends StatelessWidget {
  const _ConstCard({required this.constellation});

  final Constellation constellation;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFFBEAF0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            width: double.infinity,
            child: Image.asset(
              constellation.imageAsset,
              height: 190,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  '${constellation.name} Constellation',
                  style: const TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cycle ${constellation.cycleNumber} · '
                  '${constellation.starsEarned} '
                  '${constellation.starsEarned == 1 ? 'star' : 'stars'} · By Aura Plus',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
