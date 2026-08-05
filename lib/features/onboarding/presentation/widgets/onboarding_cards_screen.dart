import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            const Text(
              'THIS IS WHAT YOU TOLD ME',
              style: TextStyle(
                fontFamily: AppTypography.didot,
                fontSize: 13,
                letterSpacing: 2,
                color: AppColors.entryHint,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Slide to see both · tap one to edit it',
              style: TextStyle(fontSize: 12, color: AppColors.entryHint),
            ),
            Expanded(
              child: Center(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: 2,
                  onPageChanged: (i) => setState(() => _current = i),
                  // Center + scroll: el PageView da altura APRETADA, así que
                  // sin esto la card se estira a toda la pantalla, y con la
                  // frase larga (muchos sentimientos, pantalla corta)
                  // desbordaba por abajo. Así se queda de su tamaño mientras
                  // quepa, y se desplaza cuando no.
                  itemBuilder: (context, i) => Center(
                    child: SingleChildScrollView(
                      child: OnboardingCard(
                        card: i + 1,
                        state: state,
                        active: i == _current,
                        onTap: () => _tapCard(i),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _CarouselDots(current: _current),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
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
