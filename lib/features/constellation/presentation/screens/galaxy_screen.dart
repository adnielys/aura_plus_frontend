import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/constellation.dart';
import '../providers/constellation_provider.dart';

/// My sky (Bloque 2 · Q1): todos sus ciclos como cielos nocturnos apilados.
/// Solo lectura sobre `/constellation/all`. Cada ciclo muestra SU luz —
/// jamás se comparan ciclos entre sí (GUARD_TONE_03/04).
class GalaxyScreen extends ConsumerStatefulWidget {
  const GalaxyScreen({super.key});

  @override
  ConsumerState<GalaxyScreen> createState() => _GalaxyScreenState();
}

class _GalaxyScreenState extends ConsumerState<GalaxyScreen> {
  @override
  void initState() {
    super.initState();
    // Polling suave: al entrar refetchea (mismo patrón que el resto de tabs).
    Future.microtask(() {
      if (mounted) ref.invalidate(allConstellationsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final constellations = ref.watch(allConstellationsProvider);

    return Scaffold(
      body: SafeArea(
        child: constellations.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(allConstellationsProvider),
              child: const Text('Try again'),
            ),
          ),
          data: (all) {
            // La actual primero; después las cerradas, de la más reciente atrás.
            final sorted = [...all]
              ..sort((a, b) {
                if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
                return b.cycleNumber.compareTo(a.cycleNumber);
              });
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              children: [
                const SizedBox(height: 36),
                const Text(
                  'MY SKY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Every cycle you lived is still shining.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 19,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                for (final constellation in sorted) ...[
                  _SkyCard(constellation: constellation),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 6),
                const Text(
                  'Nothing here fades. The sky keeps what you built.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.constellation),
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
            );
          },
        ),
      ),
    );
  }
}

const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortDate(DateTime d) => '${_monthsShort[d.month - 1]} ${d.day}';

const _anchorLabels = {
  'self_moments': 'my moments for me',
  'my_people': 'my people',
  'small_daily': 'the small things of each day',
};

/// Tarjeta de cielo nocturno de UN ciclo (mockup Q1).
class _SkyCard extends StatelessWidget {
  const _SkyCard({required this.constellation});

  final Constellation constellation;

  @override
  Widget build(BuildContext context) {
    final c = constellation;
    final range = (c.startDate != null && c.endDate != null)
        ? '${_shortDate(c.startDate!)} — ${_shortDate(c.endDate!)}'
        : null;
    final meta = [
      ?range,
      if (c.isCurrent)
        'in progress'
      else if (c.daysPresent != null)
        '${c.daysPresent} ${c.daysPresent == 1 ? 'day' : 'days'} present',
    ].join(' · ');
    final anchor = _anchorLabels[c.reflectionAnchor];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF221833), Color(0xFF2E2144)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: c.isCurrent
            ? Border.all(color: const Color(0x66F5D9A8), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.isCurrent) ...[
                      Text(
                        'NOW · CYCLE ${c.cycleNumber}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          color: Color(0xFFF5D9A8),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontFamily: AppTypography.serif,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                        color: Color(0xFFF3EAF8),
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFFB9A8CC),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x26F5D9A8),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  '${c.starsEarned} ✦',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF5D9A8),
                  ),
                ),
              ),
            ],
          ),
          if (anchor != null) ...[
            const SizedBox(height: 8),
            Text(
              '“What stays with me: $anchor.”',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Color(0xFFD8C7E8),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _DotsRow(lit: c.litStars, total: c.starsMax),
        ],
      ),
    );
  }
}

/// Fila de estrellas del dibujo: encendidas = lo ganado (tope visual), el
/// resto en penumbra. Offsets verticales deterministas (índice), sin azar.
class _DotsRow extends StatelessWidget {
  const _DotsRow({required this.lit, required this.total});

  final int lit;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final step = constraints.maxWidth / (total + 1);
          return Stack(
            children: [
              for (var i = 0; i < total; i++)
                Positioned(
                  left: step * (i + 1),
                  top: (i.isEven ? 6 : 18) + (i % 3 == 0 ? 4 : 0),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < lit
                          ? const Color(0xFFF5D9A8)
                          : const Color(0xFF4A3B60),
                      boxShadow: i < lit
                          ? const [
                              BoxShadow(
                                color: Color(0xCCF5D9A8),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
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
