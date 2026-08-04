import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Cabecera ilustrada ESTÁNDAR de las pantallas de sección (Care · My circle ·
/// Profile): banda de altura fija con la acuarela anclada arriba y una base que
/// se difumina al fondo de la app.
///
/// La altura va en **dp fijos, no en fracción de pantalla**: con `h * 0.24` el
/// mismo asset recortaba distinto en cada móvil y las pantallas no podían
/// compartir arte. Con una altura fija, un único archivo sirve para todas y el
/// conjunto se lee como un sistema.
///
/// Los assets se diseñan a **2:1** sobre [height] (ver `docs` del equipo de
/// diseño): decoración a la derecha, mitad izquierda libre para el texto.
class SectionHero extends StatelessWidget {
  const SectionHero({
    super.key,
    required this.asset,
    required this.child,
    this.fadeTo,
  });

  /// Alto de la banda, en dp. Único punto de verdad: cambiarlo aquí lo cambia
  /// en todas las pantallas de sección.
  static const double height = 220;

  /// Proporción de diseño del arte (ancho:alto).
  static const double assetAspectRatio = 2;

  final String asset;

  /// Color al que se funde la base. Por defecto el fondo de la app; el chat de
  /// Aura pasa su papel cálido para que no quede costura.
  final Color? fadeTo;

  /// Contenido sobreimpreso (chevron, rótulo, titular…). Ya va dentro de un
  /// [SafeArea] superior.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = fadeTo ?? AppColors.background;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            // Decorativo: el titular ya dice de qué va la pantalla.
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          // Base difuminada al fondo de la app. Blanco TRANSPARENTE, nunca
          // Colors.transparent (= negro transparente): dejaría banda gris.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: height * 0.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [fade, fade.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          SafeArea(bottom: false, child: child),
        ],
      ),
    );
  }
}

/// Cabecera de sección LISTA PARA USAR: [SectionHero] + flecha atrás, rótulo en
/// carmesí y titular serif. Es el patrón de Profile · Notificaciones · Mis
/// áreas, empaquetado para que todas las subpantallas se escriban igual.
///
/// El [title] va en spans para poder resaltar la última parte en carmesí
/// itálica, como "The map of your life, *no goals.*".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.asset,
    required this.eyebrow,
    required this.title,
    required this.onBack,
    this.titleWidthFactor = 0.70,
  });

  final String asset;
  final String eyebrow;
  final List<InlineSpan> title;
  final VoidCallback onBack;

  /// Ancho del titular: acotado para que no pise la botánica de la derecha.
  final double titleWidthFactor;

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 28,
          height: 1.18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        );
    return SectionHero(
      asset: asset,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    size: 24, color: AppColors.textPrimary),
                tooltip: 'Back',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
                onPressed: onBack,
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(eyebrow,
                      style: AppTypography.sectionLabel
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: titleWidthFactor,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(TextSpan(children: title), style: serif),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
