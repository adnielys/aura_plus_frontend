import 'package:flutter/material.dart';

/// El pliegue: al cerrar un bloque, la pantalla entera se encoge hasta
/// convertirse en su card.
///
/// Es lo que hace entendible la reestructura sin una sola palabra de más: ves
/// que lo que acabas de contar NO se ha ido a ninguna parte, se ha guardado
/// ahí. Un corte seco entre pantallas obligaría a explicarlo.
///
/// La duración vive aquí y no en el controller a propósito: el estado no debe
/// saber cuánto dura una animación, y si lo supiera los tests tendrían que
/// dormir para comprobar una transición.
class OnboardingFold extends StatefulWidget {
  const OnboardingFold({
    super.key,
    required this.folding,
    required this.onFolded,
    required this.builder,
  });

  /// Lo enciende el controller al pulsar el CTA final del bloque.
  final bool folding;

  /// Se llama al terminar: es cuando el bloque da paso a lo siguiente.
  final VoidCallback onFolded;

  /// Recibe el progreso CRUDO (0 = pantalla entera, 1 = ya es card) para que
  /// quien lo use pueda apartar su pie a otro ritmo.
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<OnboardingFold> createState() => _OnboardingFoldState();
}

class _OnboardingFoldState extends State<OnboardingFold>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 720);

  /// Tamaño final: el de la card de la pantalla siguiente.
  static const _endScale = 0.44;

  /// Y sube un poco al encogerse, para que no parezca que cae.
  static const _endRise = 0.06;

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
        final eased = Curves.easeOutCubic.transform(t);
        final height = MediaQuery.of(context).size.height;
        return Transform.translate(
          offset: Offset(0, -height * _endRise * eased),
          child: Transform.scale(
            scale: 1 - (1 - _endScale) * eased,
            child: widget.builder(context, t),
          ),
        );
      },
    );
  }
}
