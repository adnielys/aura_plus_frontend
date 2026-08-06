import 'package:flutter/material.dart';

/// El cierre de un bloque: la pantalla se apaga a blanco, la card se forma en
/// su sitio, y ya formada es la que retrocede.
///
/// El orden importa. Encogiendo la pantalla entera se veía un bloque de
/// preguntas en miniatura —con sus puntos y su botón dentro— y lo que llegaba
/// a la pantalla siguiente no se parecía a lo que se había ido. Formando
/// primero la card, lo que retrocede ya ES la card: se entiende que lo que
/// contaste se ha guardado ahí, sin una palabra de más.
///
/// El fundido va a blanco porque el fondo YA es blanco: basta con apagar la
/// pantalla. Un velo por encima se vería gris.
///
/// La duración vive aquí y no en el controller a propósito: el estado no debe
/// saber cuánto dura una animación, y si lo supiera los tests tendrían que
/// dormir para comprobar una transición.
class OnboardingFold extends StatefulWidget {
  const OnboardingFold({
    super.key,
    required this.folding,
    required this.onFolded,
    required this.child,
    required this.card,
  });

  /// Lo enciende el controller al pulsar el CTA final del bloque.
  final bool folding;

  /// Se llama al terminar: es cuando el bloque da paso a lo siguiente.
  final VoidCallback onFolded;

  /// La pantalla del bloque, con sus pasos.
  final Widget child;

  /// En lo que se convierte.
  final Widget card;

  @override
  State<OnboardingFold> createState() => _OnboardingFoldState();
}

class _OnboardingFoldState extends State<OnboardingFold>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 720);

  /// Hasta aquí la pantalla se apaga y la card aparece. Después, y solo
  /// después, la card se aleja.
  static const _formUntil = 0.42;

  /// Lo que retrocede la card ya formada. No baja más porque al final del
  /// pliegue tiene que estar del tamaño en que la va a encontrar en la
  /// pantalla siguiente — si encogiera hasta un sello, aparecería de golpe.
  static const _endScale = 0.82;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) widget.onFolded();
    });

  @override
  void didUpdateWidget(covariant OnboardingFold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.folding == oldWidget.folding) return;
    if (widget.folding) {
      // Reducir movimiento: se salta el pliegue y se resuelve la transición
      // en el acto. La pantalla siguiente es la misma con o sin animación.
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
        widget.onFolded();
      } else {
        _controller.forward(from: 0);
      }
    } else {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final form = Curves.easeOut.transform((t / _formUntil).clamp(0.0, 1.0));
        final recede = Curves.easeOutCubic
            .transform(((t - _formUntil) / (1 - _formUntil)).clamp(0.0, 1.0));

        // El árbol tiene SIEMPRE la misma forma, plegando o quieto: solo
        // cambian los números. Si en reposo devolviera el hijo pelado y al
        // animar lo metiera en un Stack, Flutter no reconocería el subárbol
        // como el mismo y recrearía el paso entero — con su initState, que es
        // justo el que abre el modal de sentimientos. El modal reaparecía a
        // mitad del pliegue y, por ser una ruta, se quedaba detrás del bloque
        // siguiente.
        return LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              // La pantalla se apaga. Mientras se va, sus botones no deben
              // responder a un toque despistado.
              IgnorePointer(
                ignoring: t > 0,
                child: Opacity(opacity: 1 - form, child: widget.child),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: form,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -constraints.maxHeight * 0.04 * recede),
                      child: Transform.scale(
                        scale: 1 - (1 - _endScale) * recede,
                        child: SizedBox(
                          // La card necesita altura acotada (por dentro se
                          // reparte con un Expanded). Esta es, aproximada, la
                          // que tendrá en la pantalla de las dos cards.
                          height: constraints.maxHeight * 0.72,
                          child: widget.card,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
