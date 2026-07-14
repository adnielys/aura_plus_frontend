import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Botón principal de Aura+: forma "pill", magenta de marca.
///
/// Una sola acción por pantalla (UX_01). Estados:
/// - Deshabilitado (`onPressed == null`): opacidad 0.35, no interactivo.
/// - Cargando (`isLoading`): spinner blanco, sin texto.
/// - Activo: magenta sólido con un destello opcional (✦) como en el maquetado.
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

    return Opacity(
      opacity: isEnabled ? 1 : 0.35,
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          onPressed: isEnabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary,
            disabledForegroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label),
                    if (showSparkle) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
