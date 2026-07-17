import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/habit_icons.dart';
import '../providers/areas_presence_provider.dart';

/// "Tu cuidado, por áreas" (mockup_balance_areas aprobado): presencia
/// encendida, no rendimiento medido. 4 cápsulas en orden FIJO; un área se
/// enciende con su color al recibir un gesto (hecho o a medias) en el ciclo
/// y ya no se apaga. Las demás quedan en perla — estética, nunca "vacía".
/// Sin números por área, sin anillos, sin % (Sistema Emocional §6).
class AreasPresenceCard extends ConsumerWidget {
  const AreasPresenceCard({super.key});

  static const _style = {
    HabitArea.self: (Color(0xFFC01448), Color(0xFFFFF0F4), 'Yo'),
    HabitArea.family: (Color(0xFFE0894A), Color(0xFFFFF6EE), 'Familia'),
    HabitArea.relationships: (Color(0xFF9B6FD4), Color(0xFFF6F0FF), 'Relaciones'),
    HabitArea.work: (Color(0xFF3F7CB0), Color(0xFFEEF5FC), 'Trabajo'),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ante error o carga se muestra todo en reposo: el widget jamás bloquea
    // ni mete ruido en el Home.
    final lit = ref.watch(areasPresenceProvider).valueOrNull ?? const <HabitArea>{};
    final serif = const TextStyle(
      fontFamily: AppTypography.serif,
      fontStyle: FontStyle.italic,
      fontSize: 13.5,
      height: 1.5,
      color: AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TU CUIDADO, POR ÁREAS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final area in HabitArea.values) ...[
              Expanded(child: _AreaCapsule(area: area, lit: lit.contains(area))),
              if (area != HabitArea.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Center(
          // La frase solo ACUMULA; jamás dice cuál falta (GUARD_TONE_03/04).
          child: lit.isEmpty
              ? Text('Tus áreas se encienden con tu primer gesto ✦',
                  textAlign: TextAlign.center, style: serif)
              : Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'Este ciclo te has dado momentos en ',
                        style: serif),
                    TextSpan(
                      text:
                          '${lit.length} ${lit.length == 1 ? 'área' : 'áreas'}',
                      style: serif.copyWith(
                        color: AppColors.primary,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' de tu vida.', style: serif),
                  ]),
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    );
  }
}

class _AreaCapsule extends StatelessWidget {
  const _AreaCapsule({required this.area, required this.lit});

  final HabitArea area;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final (fg, iconBg, name) = AreasPresenceCard._style[area]!;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      // Invitación, no reproche: abre el catálogo filtrado a esa área.
      onTap: () => context.go(AppRoutes.habits, extra: area),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: lit ? Colors.transparent : AppColors.border,
          ),
          boxShadow: lit
              ? [
                  BoxShadow(
                    color: fg.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                // En reposo: perla suave (nunca un hueco por llenar).
                color: lit ? iconBg : const Color(0xFFF3EFF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                habitIconData(null, area),
                size: 19,
                color: lit ? fg : const Color(0xFFA79FAD),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              name,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: lit ? AppColors.textPrimary : const Color(0xFFA79FAD),
              ),
            ),
            SizedBox(
              height: 14,
              child: lit
                  ? Text('✦',
                      style: TextStyle(fontSize: 10, color: fg))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
