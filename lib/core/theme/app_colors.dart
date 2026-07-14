import 'package:flutter/material.dart';

/// Paleta central de Aura+.
///
/// Tono cálido y sereno, coherente con el producto: acompaña, no evalúa.
/// Alineada al maquetado (magenta `#C01448`) y a la spec Flutter. Mantener los
/// colores aquí; las pantallas nunca hardcodean valores hex.
abstract final class AppColors {
  const AppColors._();

  /// Magenta de marca. Acción principal y acentos (títulos resaltados).
  static const Color primary = Color(0xFFC01448);
  static const Color primaryDark = Color(0xFF8E0F35);

  /// Rosa suave de apoyo (fondos de tarjeta seleccionada, halos).
  static const Color secondary = Color(0xFFFF6FA1);

  /// Casi-blanco cálido. Las superficies (tarjetas) van en blanco puro encima.
  static const Color background = Color(0xFFFBF7F9);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1C1520);
  static const Color textSecondary = Color(0xFF6E6880);

  /// Fondo oscuro del cierre del día (UX_08) y de la galaxia.
  static const Color closingBackground = Color(0xFF0A0415);

  /// Estrella ganada (DailyProgressStar / constelación).
  static const Color star = Color(0xFFFF6FA1);
}

/// Colores por estado emocional (spec · EmotionalOptionCard).
///
/// Ningún estado usa rojo puro: "Al límite" es azul profundo, no error (UX_09).
/// Cada estado tiene un fondo suave y un borde/acento.
class EmotionalStateColors {
  const EmotionalStateColors({required this.background, required this.accent});

  final Color background;
  final Color accent;

  static const EmotionalStateColors energy = EmotionalStateColors(
    background: Color(0xFFFFF0F4),
    accent: Color(0xFFC01448),
  );
  static const EmotionalStateColors tranquil = EmotionalStateColors(
    background: Color(0xFFF0FBF4),
    accent: Color(0xFF2E9E5B),
  );
  static const EmotionalStateColors scattered = EmotionalStateColors(
    background: Color(0xFFF5F0FA),
    accent: Color(0xFF9B4DCA),
  );
  static const EmotionalStateColors exhausted = EmotionalStateColors(
    background: Color(0xFFF5F5F5),
    accent: Color(0xFF555555),
  );
  static const EmotionalStateColors hard = EmotionalStateColors(
    background: Color(0xFFEFF4FF),
    accent: Color(0xFF4A6FE3),
  );
}
