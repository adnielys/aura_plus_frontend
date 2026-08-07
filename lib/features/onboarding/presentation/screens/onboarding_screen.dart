import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';
import '../widgets/onboarding_block_screen.dart';
import '../widgets/onboarding_cards_screen.dart';
import '../widgets/onboarding_edit_screen.dart';

/// Flujo de onboarding (maquetado `aura_onboarding_dos_cards`): dos bloques
/// que se cierran cada uno en su card —lo personal y el día—, las dos cards
/// juntas para repasarlas, y el contrato emocional al enviar.
///
/// Esta pantalla ya no dibuja nada: solo decide cuál de las vistas toca. El
/// estado vive en el [OnboardingController], donde `stepIndex` sigue mandando
/// sobre las RESPUESTAS y `view` solo sobre lo que se ve.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Errores del envío: mensaje suave, sin detalle técnico (UX_14).
    ref.listen(
      onboardingControllerProvider.select((s) => s.errorMessage),
      (_, message) {
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
    );

    final view = switch (state.view) {
      OnboardingView.block1 => const OnboardingBlockScreen(block: 1),
      OnboardingView.block2 => const OnboardingBlockScreen(block: 2),
      OnboardingView.cards => const OnboardingCardsScreen(),
      OnboardingView.editing => const OnboardingEditScreen(),
      OnboardingView.contract => _EmotionalContract(
          name: state.name.trim(),
          onEnter: controller.enterSpace,
        ),
    };

    // Fondo propio. Sin él, mientras una pantalla se apartaba el hueco que
    // dejaba no lo cubría nadie y se veía el negro de detrás de la ruta: cada
    // vista trae su Scaffold, pero esto de aquí no era ninguna.
    return ColoredBox(
      color: Colors.white,
      // Fundido y nada más. Antes lo nuevo entraba desplazándose desde la
      // derecha, y justo después del pliegue —que acaba con la card quieta en
      // el centro— ese empujón lateral la hacía saltar: se notaba la costura
      // entre dos animaciones distintas en vez de una sola cosa que sigue.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOut,
        // El bloque 2 SUBE desde abajo, como una card que entra en la baraja;
        // la del 1 se acaba de apartar y le deja el sitio. Las demás vistas se
        // funden y ya: la de las dos cards viene de una card que se posó
        // exactamente en su hueco, y moverla ahí sería deshacerlo.
        transitionBuilder: (child, animation) {
          final entra =
              (child.key as ValueKey<OnboardingView>?)?.value ==
                  OnboardingView.block2;
          final fade = FadeTransition(opacity: animation, child: child);
          if (!entra) return fade;
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.22),
              end: Offset.zero,
            ).animate(animation),
            child: fade,
          );
        },
        // Las dos capas se cruzan en el mismo sitio, así que la que entra va
        // encima; si no, la que sale tapa a la que llega durante el cruce.
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          children: [...previous, ?current],
        ),
        // Sin esto, cambiar de vista reusaría el State del bloque anterior.
        child: KeyedSubtree(key: ValueKey(state.view), child: view),
      ),
    );
  }
}

/// Contrato emocional (SPEC_CONTENIDO_EMOCIONAL_V2 §3.2): estado de éxito del
/// onboarding. Sin metas ni presión — cierra el arco de entrada. La usuaria
/// decide cuándo entrar, con un único botón.
class _EmotionalContract extends StatefulWidget {
  const _EmotionalContract({required this.name, required this.onEnter});

  final String name;
  final VoidCallback onEnter;

  @override
  State<_EmotionalContract> createState() => _EmotionalContractState();
}

class _EmotionalContractState extends State<_EmotionalContract>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    // Arranca en el frame siguiente: lanzado dentro del propio build, el
    // primer fotograma se come el principio del fundido y el cofre aparece
    // ya puesto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Si el sistema pide reducir movimiento, la pantalla se muestra
      // entera. Una entrada bonita nunca vale una molestia física.
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.displaySmall!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Cofre y frase son UN bloque, centrado en la vertical de lo que
            // queda sobre el botón. Antes eran dos Expanded repartiendo el
            // hueco a partes iguales, pero como el cofre vive dentro del de
            // arriba, todo el aire sobrante se acumulaba debajo del texto y la
            // pantalla se leía vacía por abajo.
            //
            // El scroll es el seguro de una pantalla corta: si el bloque no
            // cabe, se desplaza en vez de desbordar (el Center lo deja quieto
            // mientras quepa).
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // La entrada va en cascada, en el orden en que se lee:
                      // cofre, destello, frase y explicación. Los tramos se
                      // solapan a propósito — encadenados de uno en uno se
                      // sentiría una cola de espera, no una llegada.
                      _Rise(
                        controller: _controller,
                        from: 0,
                        to: 0.45,
                        // Tope de altura: sin él, en pantallas estrechas y altas
                        // el contain crecía a lo alto y apretaba el texto.
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.34,
                          ),
                          child: Image.asset(
                            'assets/images/onboarding/chest.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 14, 30, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Rise(
                              controller: _controller,
                              from: 0.20,
                              to: 0.60,
                              child: const Text('✦',
                                  style: TextStyle(
                                      fontSize: 30,
                                      color: AppColors.entryAccent)),
                            ),
                            const SizedBox(height: 16),
                            // Frase-contrato: nombre en carmesí, resto en tinta.
                            _Rise(
                              controller: _controller,
                              from: 0.30,
                              to: 0.72,
                              child: Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text: "That's all I need, ",
                                    style: serif.copyWith(
                                        color: AppColors.entryInk,
                                        height: 1.35),
                                  ),
                                  TextSpan(
                                    text: widget.name,
                                    style: serif.copyWith(
                                        color: AppColors.entryAccent,
                                        height: 1.35),
                                  ),
                                  TextSpan(
                                    text: '.',
                                    style: serif.copyWith(
                                        color: AppColors.entryInk,
                                        height: 1.35),
                                  ),
                                ]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Sin salto forzado: con el \n la primera frase
                            // desbordaba y dejaba "prove." sola en su línea.
                            // Que fluya reparte líneas parejas y quita el hueco
                            // entre una frase y otra.
                            _Rise(
                              controller: _controller,
                              from: 0.42,
                              to: 0.85,
                              child: const Text(
                                'There are no goals to meet here, nothing to '
                                "prove. We begin whenever you're ready.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: AppColors.entryMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // El botón NO sube: solo se funde. Es lo único que ella puede
            // tocar, y un blanco que se mueve bajo el dedo obliga a esperar
            // a que se pare — justo lo contrario de "cuando tú quieras".
            _Rise(
              controller: _controller,
              from: 0.60,
              to: 1,
              rise: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
                child: SoftPrimaryButton(
                  label: 'Enter my space',
                  onPressed: widget.onEnter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrada de un elemento: aparece mientras sube unos píxeles, dentro de su
/// tramo [from]–[to] de la secuencia (fracciones de 0 a 1, como el splash).
/// Con [rise] a 0 se queda en el fundido, sin desplazamiento.
///
/// El progreso se calcula a mano en vez de con CurvedAnimation porque este
/// widget se reconstruye en cada fotograma: una CurvedAnimation nueva por
/// build habría que ir desechándola.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.controller,
    required this.from,
    required this.to,
    required this.child,
    this.rise = 24,
  });

  final Animation<double> controller;
  final double from;
  final double to;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: child,
      builder: (context, child) {
        final raw = ((controller.value - from) / (to - from)).clamp(0.0, 1.0);
        final t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, rise * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
