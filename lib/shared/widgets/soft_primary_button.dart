import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Botón principal de Aura+ (start-btn del maquetado): pill de 58px con
/// degradado carmesí, texto Inter ligero y el destello ✦ anclado al borde
/// derecho. Una sola acción por pantalla (UX_01). Estados:
/// - Deshabilitado (`onPressed == null`): rosa suave, no interactivo.
/// - Cargando (`isLoading`): spinner blanco, sin texto.
class SoftPrimaryButton extends StatelessWidget {
  const SoftPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.showSparkle = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showSparkle;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      height: 58,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isEnabled ? AppColors.entryGradient : null,
          // Deshabilitado: rosa sereno del maquetado, sin sombra.
          color: isEnabled ? null : const Color(0xFFF2A9C4),
          borderRadius: BorderRadius.circular(29),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppColors.entryAccent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(29),
            onTap: isEnabled ? onPressed : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: AppTypography.sans,
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                // ✦ al borde derecho (right: 26 del maquetado).
                if (showSparkle && !isLoading)
                  const Positioned(
                    right: 26,
                    child: Text(
                      '✦',
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
