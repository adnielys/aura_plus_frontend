import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/session_controller.dart';

/// Celebración del cierre (maquetado · pantalla "cierre"): la ilustración
/// ARRIBA a sangre completa con desvanecido, y el contenido anclado abajo.
/// La imagen ROTA entre 5 variantes (una nueva por cada cierre, índice
/// persistido) — así el ritual se siente fresco cada día. Solo suma: nunca
/// cuánto falta ni comparaciones (GUARD_TONE).
class CelebrateScreen extends ConsumerStatefulWidget {
  const CelebrateScreen({super.key});

  @override
  ConsumerState<CelebrateScreen> createState() => _CelebrateScreenState();
}

class _CelebrateScreenState extends ConsumerState<CelebrateScreen> {
  static const _images = [
    'assets/images/session/celebrate1.jpg',
    'assets/images/session/celebrate2.jpg',
    'assets/images/session/celebrate3.jpg',
    'assets/images/session/celebrate4.jpg',
    'assets/images/session/celebrate5.jpg',
  ];

  String _image = _images.first;

  @override
  void initState() {
    super.initState();
    _rotateImage();
  }

  /// rotateCierreGirl del maquetado: avanza el índice y lo persiste.
  Future<void> _rotateImage() async {
    final prefs = await SharedPreferences.getInstance();
    final next = ((prefs.getInt('cierre_girl_idx') ?? -1) + 1) % _images.length;
    await prefs.setInt('cierre_girl_idx', next);
    if (mounted) setState(() => _image = _images[next]);
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(sessionControllerProvider).valueOrNull;

    if (result == null) {
      return const Scaffold(
        backgroundColor: AppColors.closingBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.star),
        ),
      );
    }

    final stars = result.session.starsEarned;

    return Scaffold(
      // Degradado exacto del maquetado (.celebrate).
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.55, 1],
            colors: [Color(0xFF2A0A22), Color(0xFF1E081A), Color(0xFF140610)],
          ),
        ),
        child: Stack(
          children: [
            // Ilustración ARRIBA a sangre, desvanecida hacia el contenido
            // (mask-image del maquetado: sólida hasta 80%, transparente al 100%).
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.sizeOf(context).height * 0.58,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.8, 0.92, 1],
                  colors: [
                    Colors.black,
                    Colors.black,
                    Colors.black54,
                    Colors.transparent,
                  ],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  _image,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            // Contenido anclado abajo (celebrate-top).
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _AuraSparks(),
                    const SizedBox(height: 14),
                    Text(
                      'You showed up today',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                            fontSize: 24,
                          ),
                    ),
                    const SizedBox(height: 10),
                    // El mensaje de cierre lo escribe el SERVIDOR.
                    Text(
                      result.session.closingMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // stars-won del maquetado: texto plano en rosa, w700.
                    Text(
                      '+$stars ${stars == 1 ? 'star' : 'stars'} · '
                      '${result.constellation.name} constellation',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.star,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () => context.go(AppRoutes.constellation),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'See my constellation',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Positioned(
                                right: 22,
                                child: Text(
                                  '✦',
                                  style: TextStyle(
                                      fontSize: 13, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: Text(
                        'Go to start →',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El doble destello de Aura del maquetado (dos estrellas de 4 puntas).
class _AuraSparks extends StatelessWidget {
  const _AuraSparks();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 66,
      child: CustomPaint(
        size: Size(66, 66),
        painter: _SparksPainter(),
      ),
    );
  }
}

class _SparksPainter extends CustomPainter {
  const _SparksPainter();

  void _spark(Canvas canvas, Offset origin, double s, Paint paint) {
    final path = Path()
      ..moveTo(origin.dx + 50 * s, origin.dy + 3 * s)
      ..cubicTo(origin.dx + 53 * s, origin.dy + 32 * s, origin.dx + 68 * s,
          origin.dy + 47 * s, origin.dx + 97 * s, origin.dy + 50 * s)
      ..cubicTo(origin.dx + 68 * s, origin.dy + 53 * s, origin.dx + 53 * s,
          origin.dy + 68 * s, origin.dx + 50 * s, origin.dy + 97 * s)
      ..cubicTo(origin.dx + 47 * s, origin.dy + 68 * s, origin.dx + 32 * s,
          origin.dy + 53 * s, origin.dx + 3 * s, origin.dy + 50 * s)
      ..cubicTo(origin.dx + 32 * s, origin.dy + 47 * s, origin.dx + 47 * s,
          origin.dy + 32 * s, origin.dx + 50 * s, origin.dy + 3 * s)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final center = Offset(size.width / 2 - 33, 0);
    // Proporciones del SVG del maquetado: grande 0.75 + pequeña 0.38.
    _spark(canvas, center + const Offset(4.5, 2.5), 0.5, paint);
    _spark(canvas, center + const Offset(38, 34), 0.25, paint);
  }

  @override
  bool shouldRepaint(_SparksPainter oldDelegate) => false;
}
