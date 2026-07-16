import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografía de Aura+, las TRES voces del maquetado `aura_preview`:
/// - **Poltawski Nowy** ([serif]): frases del onboarding, titulares emocionales.
/// - **GFS Didot** ([didot]): marca y eyebrows en mayúsculas espaciadas
///   ("ASÍ TE SIENTES HOY", "BUENAS TARDES").
/// - **Inter** ([sans]): cuerpo, tarjetas y controles (fuente por defecto).
abstract final class AppTypography {
  const AppTypography._();

  static const String serif = 'Poltawski Nowy';
  static const String didot = 'GFS Didot';
  static const String sans = 'Inter';

  /// Eyebrow del maquetado: GFS Didot, mayúsculas, espaciada, en el acento.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: didot,
    fontSize: 13,
    letterSpacing: 2,
    color: AppColors.entryAccent,
  );

  /// Etiqueta de sección de la zona app (.label): pequeña, firme, muted.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

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
        // Cuerpo y subtítulos (Inter, como el maquetado).
        bodyLarge: TextStyle(
          fontFamily: sans,
          fontSize: 16,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: sans,
          fontSize: 14,
          height: 1.45,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: sans,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
}
