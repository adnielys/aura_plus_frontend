import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/notifications/local_daily_notifications.dart';
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

  /// Ancho del logo en el maquetado (`.splash-logo{width:150px}`).
  static const _logoWidth = 150.0;

  /// Alto = ancho · relación del viewBox del SVG (176 × 176,4).
  static const _logoHeight = _logoWidth * 176.4 / 176;

  /// Dónde aterriza el destello: el hueco de la estrella DENTRO del logo.
  /// En el viewBox la estrella ocupa x 39,6–77,7 e y 74,1–112,2 —centro
  /// (58,65 · 93,15)— y el logo se centra en (88 · 88,2); la diferencia,
  /// escalada a 150 px, da este desplazamiento. Su lado (38,1) escalado son
  /// 32,5 px, o sea 0,18 del destello de 180: de ahí el factor de encogido.
  static const _sparkLanding = Offset(-25.0, 4.2);

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
      // El idioma del teléfono, solo la PRIMERA vez: a partir de ahí manda
      // el que ella haya elegido (a diferencia de la timezone, que es hecho).
      await syncDeviceLanguage(ref);
      if (!mounted) return;
      // Push (FCM): registra el token para LA notificación diaria. No-op sin
      // google-services.json; jamás bloquea el arranque.
      await registerPushToken(ref);
      if (!mounted) return;
      await ref.read(onboardingStatusProvider.notifier).refresh();
      if (!mounted) return;
      // La diaria LOCAL: refresca la ventana de 14 días en cada arranque
      // (sin onboarding aún no hay ajustes: el catch lo deja pasar).
      try {
        final settings = await ref.read(notificationSettingsProvider.future);
        await scheduleDailyNotifications(
          enabled: settings.isEnabled,
          preferredTime: settings.preferredTime,
        );
      } catch (_) {}
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
          // Aterriza EN la estrella del logo, no junto a él.
          final sparkOffset = _sparkLanding * sparkFall;

          // 1950–2600 ms: la "A" barre de arriba abajo. 2450–3000: el nombre
          // barre de izquierda a derecha. La curva es el cubic-bezier
          // (.4,0,.2,1) del maquetado, que en Flutter es fastOutSlowIn.
          final markWipe = Curves.fastOutSlowIn.transform(_t(1950, 2600));
          final wordWipe = Curves.fastOutSlowIn.transform(_t(2450, 3000));

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
                  offset: sparkOffset,
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
              // El logo REAL (aura_logo.svg), quieto en el centro y revelado
              // en dos capas recortadas, como el maquetado. La estrella que
              // el propio logo trae queda siempre fuera del recorte (el
              // recorte de la marca empieza en el 45%): su sitio lo ocupa el
              // destello animado, que para eso aterriza justo ahí.
              SizedBox(
                width: _logoWidth,
                height: _logoHeight,
                child: Stack(
                  children: [
                    // La "A": el borde inferior del recorte baja del 100% al
                    // 35%, así se descubre de arriba abajo.
                    ClipRect(
                      clipper: _InsetClipper(
                        left: 0.45,
                        bottom: 1 - 0.65 * markWipe,
                      ),
                      child: const _AuraLogo(),
                    ),
                    // "AURA PLUS": la banda entre el 70% y el 82% de la
                    // altura, descubierta de izquierda a derecha.
                    ClipRect(
                      clipper: _InsetClipper(
                        top: 0.70,
                        bottom: 0.18,
                        right: 1 - wordWipe,
                      ),
                      child: const _AuraLogo(),
                    ),
                  ],
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

/// El logo, siempre en blanco: el maquetado lo blanquea con
/// `filter:brightness(0) invert(1)` y aquí basta teñir el SVG.
class _AuraLogo extends StatelessWidget {
  const _AuraLogo();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/aura_logo.svg',
      width: _SplashScreenState._logoWidth,
      height: _SplashScreenState._logoHeight,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  }
}

/// Recorte por fracciones del lado, equivalente al `inset()` de CSS con el
/// que el maquetado descubre cada parte del logo. Un borde que se cruza con
/// el opuesto deja el rectángulo vacío, que es justo el estado inicial.
class _InsetClipper extends CustomClipper<Rect> {
  const _InsetClipper({
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.left = 0,
  });

  final double top;
  final double right;
  final double bottom;
  final double left;

  @override
  Rect getClip(Size size) {
    final l = size.width * left;
    final t = size.height * top;
    return Rect.fromLTRB(
      l,
      t,
      math.max(l, size.width * (1 - right)),
      math.max(t, size.height * (1 - bottom)),
    );
  }

  @override
  bool shouldReclip(_InsetClipper oldClipper) =>
      oldClipper.top != top ||
      oldClipper.right != right ||
      oldClipper.bottom != bottom ||
      oldClipper.left != left;
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
