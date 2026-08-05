import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/onboarding_controller.dart';
import 'onboarding_sentence.dart';

/// Una de las dos cards: lo que le has contado, guardado.
///
/// No es un resumen administrativo — es la frase entera, con sus palabras, en
/// pequeño. Por eso conserva el serif y el carmesí de los valores: leerla
/// tiene que sentirse como releer lo que dijiste, no como revisar un
/// formulario relleno.
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
            width: 300,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: active
                    ? AppColors.entryAccent.withValues(alpha: 0.35)
                    : AppColors.entryBorder,
                width: 1.5,
              ),
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x29D60B52),
                        blurRadius: 40,
                        offset: Offset(0, 18),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card == 1 ? 'THIS IS HOW YOU FEEL' : 'AND THIS IS YOUR DAY',
                  style: const TextStyle(
                    fontFamily: AppTypography.didot,
                    fontSize: 11,
                    letterSpacing: 2,
                    color: AppColors.entryHint,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: Image.asset(
                    'assets/images/onboarding/feelings-header.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                _CardSentence(card: card, state: state),
                const SizedBox(height: 16),
                const Text(
                  'Tap to edit ✎',
                  style: TextStyle(fontSize: 11.5, color: AppColors.entryHint),
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
      fontSize: 16.5,
      height: 1.5,
      color: AppColors.entryInk,
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
