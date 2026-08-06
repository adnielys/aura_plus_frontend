import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';
import 'onboarding_bits.dart';
import 'onboarding_card.dart';

/// Las dos cards, juntas: lo que le has contado antes de empezar.
///
/// Es el único sitio del onboarding donde se ve TODO a la vez, y por eso es el
/// que envía. Que las dos quepan en una pantalla es la promesa cumplida: no
/// era un cuestionario largo, eran dos cosas.
class OnboardingCardsScreen extends ConsumerStatefulWidget {
  const OnboardingCardsScreen({super.key});

  @override
  ConsumerState<OnboardingCardsScreen> createState() =>
      _OnboardingCardsScreenState();
}

class _OnboardingCardsScreenState
    extends ConsumerState<OnboardingCardsScreen> {
  late final PageController _pages;
  late int _current;

  @override
  void initState() {
    super.initState();
    // Volver de editar deja la card corregida delante, no la primera: quien
    // acaba de tocar una palabra quiere ver esa.
    _current = ref.read(onboardingControllerProvider).editingCard - 1;
    // 0.82 deja asomar el borde de la siguiente. Sin ese trozo visible, nadie
    // adivina que hay una segunda card — y el "slide to see both" sería una
    // instrucción en vez de una pista.
    _pages = PageController(viewportFraction: 0.82, initialPage: _current);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Tocar la card lateral la trae al centro; tocar la centrada la abre.
  void _tapCard(int index) {
    if (index != _current) {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    ref.read(onboardingControllerProvider.notifier).openCard(index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      // Blanco cálido: sobre blanco puro las cards blancas no se despegarían.
      backgroundColor: AppColors.entrySurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sin flecha de volver: no hay a dónde: cada dato se corrige
            // tocando su card, que es más corto que rehacer el recorrido.
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              // El cabezal de Home, sin retoques: headlineMedium (serif 24
              // bold). Es el mismo gesto —titular de pantalla— y con su propio
              // tamaño y espaciado se leía como otra app.
              child: Text(
                'THIS IS WHAT YOU TOLD ME',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Slide to see both · tap one to edit it',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            Expanded(
              child: Center(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: 2,
                  // El PageView recorta a sus hijos por defecto, y cortaba la
                  // sombra de la card en seco justo en el borde del visor: se
                  // veía una raya, no una sombra. Con Clip.none respira fuera,
                  // y como los puntos van DESPUÉS en la Column se pintan
                  // encima de ella.
                  clipBehavior: Clip.none,
                  onPageChanged: (i) => setState(() => _current = i),
                  // Sin Center: la card RECIBE la altura apretada del PageView
                  // y la ocupa entera. Es lo que hace que las dos midan igual
                  // — el desborde lo resuelve la card por dentro.
                  itemBuilder: (context, i) => OnboardingCard(
                    card: i + 1,
                    state: state,
                    active: i == _current,
                    onTap: () => _tapCard(i),
                  ),
                ),
              ),
            ),
            // Sitio para que la sombra caiga antes de los puntos.
            const SizedBox(height: 16),
            _CarouselDots(current: _current),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: SoftPrimaryButton(
                label: 'Start with Aura+',
                // Aquí, y solo aquí, se envía. Los bloques ya no lo hacen.
                onPressed: state.isBlockComplete(1) && state.isBlockComplete(2)
                    ? controller.submit
                    : null,
                isLoading: state.isSubmitting,
              ),
            ),
            const CancelLink(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Dos puntos: en qué card estás. El activo se alarga, como los del flujo.
class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 2; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.entryAccent
                  : AppColors.entryBorder,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
      ],
    );
  }
}
