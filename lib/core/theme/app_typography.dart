import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografía de Aura+.
///
/// Dos voces, como en el maquetado:
/// - **Serif** ([serif]) para los títulos/"frases" del onboarding y mensajes de
///   Aura: cálida, editorial, humana.
/// - **Sans** del sistema para el cuerpo y los controles: neutra y legible.
///
/// Serif de marca: **Poltawski Nowy**, bundleada desde el maquetado
/// (`assets/fonts/`). Funciona igual en Android e iOS.
abstract final class AppTypography {
  const AppTypography._();

  static const String serif = 'Poltawski Nowy';

  static TextTheme get textTheme => const TextTheme(
        // Las "frases" grandes del onboarding y titulares emocionales.
        displaySmall: TextStyle(
          fontFamily: serif,
          fontSize: 30,
          height: 1.38,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: serif,
          fontSize: 24,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: serif,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Cuerpo y subtítulos (sans del sistema).
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );
}
