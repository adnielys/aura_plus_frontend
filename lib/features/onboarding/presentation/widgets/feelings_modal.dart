import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';

/// Modal de sentimientos del onboarding (paso 4). Salió de
/// onboarding_screen.dart sin tocarle el comportamiento.

/// Modal del maquetado (feel-modal): pantalla completa con título serif, grid
/// de 3 columnas con ilustraciones y "Listo". Multi-selección.
class FeelingsModal extends ConsumerWidget {
  const FeelingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feelings = ref.watch(
      onboardingControllerProvider.select((s) => s.feelings),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    final serif = Theme.of(context).textTheme.headlineMedium!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Cruz de cerrar: el modal se abre solo al llegar al paso, así que
            // la salida tiene que estar a la vista. Antes solo se salía
            // eligiendo un sentimiento.
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(CupertinoIcons.xmark,
                    size: 20, color: AppColors.entryInk),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Text(
              'How do you feel today?',
              textAlign: TextAlign.center,
              style: serif.copyWith(color: AppColors.entryAccent, fontSize: 26),
            ),
            const SizedBox(height: 4),
            const Text(
              'choose all that apply',
              style: TextStyle(fontSize: 13, color: AppColors.entryHint),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                crossAxisCount: 3,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                childAspectRatio: 0.74,
                children: [
                  for (final feeling in Feeling.values)
                    FeelingCard(
                      feeling: feeling,
                      selected: feelings.contains(feeling),
                      onTap: () => controller.toggleFeeling(feeling),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
              child: SoftPrimaryButton(
                label: 'Done',
                onPressed:
                    feelings.isEmpty ? null : () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta del grid de sentimientos (estilo aprobado): fondo blanco limpio,
/// la ilustración en un marco interior redondeado y el nombre en serif debajo.
/// Seleccionada: borde rosado más presente + sombra suave (sin cambiar fondo).
class FeelingCard extends StatelessWidget {
  const FeelingCard({
    super.key,
    required this.feeling,
    required this.selected,
    required this.onTap,
  });

  final Feeling feeling;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.entryAccent : AppColors.entryBorder,
            width: selected ? 1.6 : 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.entryAccent.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Ilustración sin marco interior: solo el borde externo de la card.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(feeling.imageAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              feeling.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: AppTypography.serif,
                fontSize: 12.5,
                height: 1.12,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
