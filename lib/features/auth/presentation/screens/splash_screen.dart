import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/push_registrar.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/auth_controller.dart';

/// Splash animado (maquetado `aura_preview` · secuencia de 3.3 s sobre fondo
/// carmesí): un punto blanco florece, se abre el destello de 4 puntas con tres
/// mini-destellos, el destello cae encogiéndose y "AURA PLUS" se revela con un
/// barrido. Al terminar recién se restaura la sesión, para que el router no
/// corte la animación.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _crimson = Color(0xFFD60B51);
  static const _duration = Duration(milliseconds: 3300);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..forward().whenComplete(_boot);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Restaura la sesión y, si sigue viva, resuelve el estado de onboarding para
  /// que el router pueda decidir entre onboarding y home.
  Future<void> _boot() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
    if (!mounted) return;
    final isAuthenticated =
        ref.read(authControllerProvider).status == AuthStatus.authenticated;
    if (isAuthenticated) {
      // ANTES de cualquier consulta del día: el servidor calcula "su hoy" con
      // la timezone del dispositivo (si falla, no bloquea el arranque).
      await syncDeviceTimezone(ref);
      if (!mounted) return;
      // Push (FCM): registra el token para LA notificación diaria. No-op sin
      // google-services.json; jamás bloquea el arranque.
      await registerPushToken(ref);
      if (!mounted) return;
      await ref.read(onboardingStatusProvider.notifier).refresh();
    }
  }

  /// Progreso [0,1] dentro de la ventana ms [from, to] de la secuencia.
  double _t(int from, int to) {
    final total = _duration.inMilliseconds;
    final value = _controller.value * total;
    return ((value - from) / (to - from)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crimson,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
          // 0–450 ms: el punto florece; 500–800: se disuelve creciendo.
          final dotIn = Curves.easeOutBack.transform(_t(0, 450));
          final dotOut = Curves.easeOut.transform(_t(500, 800));

          // 450–1350 ms: destello principal (escala con rebote y giro).
          final sparkIn = Curves.easeOutBack.transform(_t(450, 1350));
          // 1400–2100 ms: cae y se encoge hacia el logo.
          final sparkFall = Curves.easeInOut.transform(_t(1400, 2100));
          final sparkScale =
              (0.2 + 0.8 * sparkIn) * (1 - 0.82 * sparkFall);
          final sparkAngle = (-45 + 45 * sparkIn) * math.pi / 180;
          final sparkDy = -96.0 * sparkFall; // aterriza junto al logo

          // 2450–3000 ms: barrido del nombre. 1950–2600: aparece la marca.
          final markIn = Curves.easeOut.transform(_t(1950, 2600));
          final wordWipe = Curves.easeInOut.transform(_t(2450, 3000));

          return Stack(
            alignment: Alignment.center,
            children: [
              // Punto/semilla inicial.
              if (dotOut < 1)
                Opacity(
                  opacity: (dotIn * (1 - dotOut)).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: dotIn * (1 + 1.4 * dotOut),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              // Mini destellos que titilan mientras el principal se abre.
              _MiniSpark(t: _t(550, 1100), dx: -72, dy: -56, size: 34),
              _MiniSpark(t: _t(720, 1270), dx: 80, dy: -30, size: 26),
              _MiniSpark(t: _t(900, 1450), dx: 50, dy: 66, size: 30),
              // Destello principal de 4 puntas.
              if (sparkIn > 0)
                Transform.translate(
                  offset: Offset(0, sparkDy),
                  child: Transform.rotate(
                    angle: sparkAngle,
                    child: Transform.scale(
                      scale: sparkScale,
                      child: const CustomPaint(
                        size: Size(180, 180),
                        painter: _AuraSparkPainter(),
                      ),
                    ),
                  ),
                ),
              // Logo: "AURA PLUS" fijo al centro, revelado con barrido
              // izquierda→derecha (el recorte crece, el texto no se mueve).
              Transform.translate(
                offset: const Offset(0, 4),
                child: Opacity(
                  opacity: markIn,
                  child: ClipRect(
                    clipper: _WipeClipper(progress: wordWipe),
                    child: Text(
                      'AURA PLUS',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                            color: Colors.white,
                            fontSize: 30,
                            letterSpacing: 6,
                          ),
                    ),
                  ),
                ),
              ),
            ],
            );
          },
        ),
      ),
    );
  }
}

/// Recorte de barrido izquierda→derecha (wordWipe del maquetado).
class _WipeClipper extends CustomClipper<Rect> {
  const _WipeClipper({required this.progress});

  final double progress;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_WipeClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Mini destello: aparece girando, brilla y se apaga (miniTwinkle).
class _MiniSpark extends StatelessWidget {
  const _MiniSpark({
    required this.t,
    required this.dx,
    required this.dy,
    required this.size,
  });

  final double t;
  final double dx;
  final double dy;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    // 0→0.45: crece y aparece; 0.45→1: se apaga encogiendo.
    final rising = (t / 0.45).clamp(0.0, 1.0);
    final fading = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    final scale = fading == 0 ? 0.1 + 0.9 * rising : 1 - 0.7 * fading;
    final opacity = fading == 0 ? rising : 1 - fading;
    final angle = (-30 + 50 * t) * math.pi / 180;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              size: Size(size, size),
              painter: const _AuraSparkPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

/// El destello de 4 puntas de Aura (path del maquetado, viewBox 0 0 100 100).
class _AuraSparkPainter extends CustomPainter {
  const _AuraSparkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final path = Path()
      ..moveTo(50 * s, 3 * s)
      ..cubicTo(53 * s, 32 * s, 68 * s, 47 * s, 97 * s, 50 * s)
      ..cubicTo(68 * s, 53 * s, 53 * s, 68 * s, 50 * s, 97 * s)
      ..cubicTo(47 * s, 68 * s, 32 * s, 53 * s, 3 * s, 50 * s)
      ..cubicTo(32 * s, 47 * s, 47 * s, 32 * s, 50 * s, 3 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_AuraSparkPainter oldDelegate) => false;
}
