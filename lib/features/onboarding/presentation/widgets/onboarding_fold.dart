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
    this.recedes = false,
  });

  /// Lo enciende el controller al pulsar el CTA final del bloque.
  final bool folding;

  /// Se llama al terminar: es cuando el bloque da paso a lo siguiente.
  final VoidCallback onFolded;

  /// La pantalla del bloque, con sus pasos.
  final Widget child;

  /// En lo que se convierte.
  final Widget card;

  /// Si la card se APARTA en vez de posarse.
  ///
  /// El bloque 1 da paso al 2, que sube desde abajo: su card tiene que dejar
  /// sitio, así que se aleja y se va. El bloque 2 da paso a la pantalla que
  /// muestra las dos, y ahí su card se queda — se posa justo en el hueco donde
  /// la siguiente pantalla la va a dibujar.
  final bool recedes;

  @override
  State<OnboardingFold> createState() => _OnboardingFoldState();
}

class _OnboardingFoldState extends State<OnboardingFold>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 720);

  /// Hasta aquí la pantalla se apaga y la card aparece. Después, y solo
  /// después, la card se posa.
  static const _formUntil = 0.42;

  /// Dónde acaba la card: EXACTAMENTE el hueco que ocupa en la pantalla de las
  /// dos cards, medido en un Pixel 6 (337×626 sobre 411×914, centrada 24 px
  /// por encima del centro). Antes acababa en otro sitio y de otro tamaño, y
  /// el salto al cambiar de pantalla era lo que hacía que el pliegue se
  /// sintiera forzado: dos animaciones con una costura en medio en vez de un
  /// solo movimiento.
  ///
  /// Son proporciones, no píxeles, así que aguantan otros tamaños de pantalla;
  /// no son exactas porque el cabezal y el botón de destino no crecen con el
  /// alto, pero el desajuste que queda es de unos pocos píxeles.
  static const _endWidth = 0.821;
  static const _endHeight = 0.685;
  static const _endRise = 0.026;

  /// Se forma más grande que su destino y se posa: viene de ocupar la pantalla
  /// entera, así que aparecer ya del tamaño final se leería como un corte.
  static const _startScale = 1.22;

  /// A dónde se va la card que se aparta: más lejos y desvanecida, para dejar
  /// el sitio limpio a la que sube desde abajo.
  static const _awayScale = 0.74;

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
                  // Apartándose se desvanece al alejarse; posándose se queda.
                  opacity: widget.recedes ? form * (1 - recede) : form,
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        -constraints.maxHeight * _endRise * recede,
                      ),
                      child: Transform.scale(
                        // Posándose, 1.22 → 1: la caja YA es la del destino,
                        // así que al acabar la escala sobra y la card queda
                        // clavada donde la pantalla siguiente la va a dibujar.
                        // Apartándose sigue de largo hasta 0.74, que es lo que
                        // se lee como "se va", no como "se coloca".
                        scale: widget.recedes
                            ? _startScale +
                                (_awayScale - _startScale) * recede
                            : 1 + (_startScale - 1) * (1 - recede),
                        child: SizedBox(
                          width: constraints.maxWidth * _endWidth,
                          height: constraints.maxHeight * _endHeight,
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
