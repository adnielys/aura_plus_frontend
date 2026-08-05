import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Diálogo de confirmación de Aura+. Una sola pieza para toda la app: siete
/// pantallas lo escribían a mano y habían derivado a cuatro estilos distintos
/// (algunas ya eran Material puro), así que preguntar lo mismo se veía
/// diferente según por dónde llegaras.
///
/// El tono lo fija la forma: título en serif cursiva (la voz de Aura), cuerpo
/// que explica QUÉ pasa y qué NO se pierde, salida neutra a la izquierda y
/// acción en carmesí a la derecha. Nunca hay una opción "mala": quedarse es
/// una respuesta tan válida como seguir.
///
/// Devuelve `true` solo si toca la acción. Cerrar por fuera o con "atrás"
/// cuenta como NO — un roce jamás confirma nada.
Future<bool> showAuraConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,

  /// Carmesí de marca por defecto. La entrada usa el suyo ([AppColors
  /// .entryAccent]) y el carril de cuidado el verde sereno ([AppColors
  /// .careAccent]): dentro de esos mundos, el magenta sería un extraño.
  Color accent = AppColors.primary,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTypography.serif,
          fontStyle: FontStyle.italic,
          fontSize: 20,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(fontWeight: FontWeight.w700, color: accent),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
