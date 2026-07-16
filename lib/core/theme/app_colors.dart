import 'package:flutter/material.dart';

/// Paleta central de Aura+, levantada del maquetado `aura_preview`.
///
/// El maquetado define DOS zonas de color:
/// - **Entrada** (splash/bienvenida/onboarding, `:root`): fondo blanco puro,
///   texto gris cálido y un carmesí más vivo ([entryAccent]).
/// - **App** (tabs y flujo diario, `.ap-stage`): fondo #FAFAFA, tinta #1C1520
///   y el magenta de marca ([primary]).
/// Mantener los colores aquí; las pantallas nunca hardcodean valores hex.
abstract final class AppColors {
  const AppColors._();

  // ── Zona app (.ap-stage del maquetado) ────────────────────────────────────
  /// Magenta de marca (--crimson). Acción principal y acentos.
  static const Color primary = Color(0xFFC01448);
  static const Color primaryDark = Color(0xFF8E0F35);

  /// Rosa de apoyo (--rose): halos, estrella, resaltes suaves.
  static const Color secondary = Color(0xFFFF6FA1);

  /// Fondo de la zona app (--bg) y superficies (tarjetas en blanco).
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);

  /// Superficie lila suave (--surface): pills, iconos en cápsula.
  static const Color surfaceTint = Color(0xFFF5F0FA);

  /// Borde de tarjetas de la zona app (--border).
  static const Color border = Color(0xFFEDD5E0);

  static const Color textPrimary = Color(0xFF1C1520); // --ink
  static const Color textSecondary = Color(0xFF6B6273); // --muted

  /// Fondo oscuro del cierre del día y la galaxia (--abyss profundo).
  static const Color closingBackground = Color(0xFF0A0415);

  /// Estrella ganada (constelación).
  static const Color star = Color(0xFFFF6FA1);

  // ── Zona de entrada (:root del maquetado) ──────────────────────────────────
  /// Carmesí vivo de la entrada (--primary #d60b52): título de bienvenida,
  /// valores de la frase, eyebrows del onboarding y CTA degradado.
  static const Color entryAccent = Color(0xFFD60B52);
  static const Color entryAccentDark = Color(0xFFB30743);

  /// Texto principal de la frase del onboarding (--text-main).
  static const Color entryInk = Color(0xFF5D5D5D);

  /// Gris del párrafo de bienvenida (copy p).
  static const Color entryMuted = Color(0xFF8A8A8A);

  /// Pistas pequeñas del onboarding (.ob-hint).
  static const Color entryHint = Color(0xFF9B8088);

  /// Placeholder de la frase (seg-val vacío) y bordes rosados de la entrada.
  static const Color entryPlaceholder = Color(0xFFE2A9BF);
  static const Color entryBorder = Color(0xFFF0C3D3);

  /// Degradado del CTA de la entrada (start-btn).
  static const LinearGradient entryGradient = LinearGradient(
    colors: [entryAccent, entryAccentDark],
  );
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
