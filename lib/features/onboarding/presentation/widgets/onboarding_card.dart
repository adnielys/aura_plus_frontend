import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/onboarding_controller.dart';
import 'onboarding_bits.dart';
import 'onboarding_sentence.dart';

/// Una de las dos cards: lo que le has contado, guardado.
///
/// No es un resumen administrativo — es la frase entera, con sus palabras. Por
/// eso conserva el serif y el carmesí de los valores: leerla tiene que
/// sentirse como releer lo que dijiste, no como revisar un formulario.
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.card,
    required this.state,
    required this.active,
    required this.onTap,
  });

  /// 1 = lo personal, 2 = el día.
  final int card;
  final OnboardingState state;

  /// La card centrada. La otra asoma por el borde, apagada.
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: active ? 1 : 0.55,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          scale: active ? 1 : 0.94,
          child: Container(
            // Sin ancho fijo: ocupa su hueco del carrusel, así que en una
            // pantalla ancha crece en vez de quedarse como una pastilla.
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.entryBorder, width: 1),
              // Sombra apenas perceptible: la card se despega del fondo
              // cálido sin parecer que flota por encima de la pantalla.
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x14D60B52),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            // Altura APRETADA desde el PageView: las dos miden exactamente lo
            // mismo aunque una frase sea más larga que la otra. Antes cada una
            // se ajustaba a su contenido y se veían desiguales.
            child: Column(
              children: [
                Text(
                  card == 1 ? 'THIS IS HOW YOU FEEL' : 'AND THIS IS YOUR DAY',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.didot,
                    fontSize: 14,
                    letterSpacing: 2.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                // El contenido va centrado en el hueco que quede, y se
                // desplaza solo si de verdad no cabe.
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Image.asset(blockImage(card), fit: BoxFit.contain),
                          const SizedBox(height: 18),
                          _CardSentence(card: card, state: state),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Pastilla y no texto suelto: dice que se puede TOCAR. De
                // texto plano se leía como un pie de foto.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.entryBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tap to edit',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.entryHint,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.edit_outlined,
                          size: 15, color: AppColors.entryPlaceholder),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La frase del bloque a tamaño de card. Los textos son los MISMOS que en los
/// pasos —salen de las mismas tablas— para que no puedan divergir: si aquí se
/// escribieran a mano, cambiar una palabra en el flujo dejaría la card
/// diciendo otra cosa.
class _CardSentence extends StatelessWidget {
  const _CardSentence({required this.card, required this.state});

  final int card;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    const serif = TextStyle(
      fontFamily: AppTypography.serif,
      fontSize: 21,
      height: 1.5,
      color: AppColors.textPrimary,
    );

    TextSpan value(String? text, String placeholder) => TextSpan(
          text: text ?? placeholder,
          style: serif.copyWith(
            color: text == null
                ? AppColors.entryPlaceholder
                : AppColors.entryAccent,
            fontWeight: text == null ? FontWeight.w400 : FontWeight.w700,
            fontStyle: text == null ? FontStyle.italic : FontStyle.normal,
          ),
        );

    final spans = card == 1
        ? [
            const TextSpan(text: 'My name is ', style: serif),
            value(state.name.trim().isEmpty ? null : state.name.trim(),
                'your name'),
            const TextSpan(text: ', I am ', style: serif),
            value(state.age?.toString(), '··'),
            const TextSpan(text: ' years old with ', style: serif),
            value(state.childrenCount?.toString(), '··'),
            TextSpan(
              text: (state.childrenCount ?? 2) == 1 ? ' child. ' : ' children. ',
              style: serif,
            ),
            const TextSpan(text: 'I feel ', style: serif),
            value(joinFeelings(state.feelings), 'like this'),
            const TextSpan(text: '.', style: serif),
          ]
        : [
            const TextSpan(text: 'Right now, the hardest part is ',
                style: serif),
            value(painValue[state.mainPain], 'this'),
            const TextSpan(text: '. Each day, I have about ', style: serif),
            value(timeValue[state.dailyTimeSlot], 'some time'),
            const TextSpan(text: ' for myself. My Aura+ moment is ',
                style: serif),
            value(momentValue[state.preferredMoment], 'yours to choose'),
            const TextSpan(text: '.', style: serif),
          ];

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
      style: serif,
    );
  }
}
