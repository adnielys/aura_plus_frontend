import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/aura_dialog.dart';
import '../providers/onboarding_controller.dart';

/// Piezas sueltas del onboarding, compartidas por los bloques y las cards.
/// Salieron de onboarding_screen.dart sin tocarles el comportamiento.

/// Puntos de progreso: el paso activo se alarga en magenta (como el maquetado).
///
/// Cuenta por BLOQUE, no por el onboarding entero: siete puntos hacían el
/// camino largo de mirar, y partido en dos cards el segundo bloque volvería a
/// empezar en el punto cinco, que se lee como ir por la mitad cuando ya vas
/// por el principio de otra cosa.
class StepDots extends StatelessWidget {
  const StepDots({
    super.key,
    required this.block,
    required this.active,
    required this.count,
  });

  /// Bloque al que pertenecen estos puntos (1 o 2).
  final int block;

  /// Paso activo dentro del bloque, 1-indexado.
  final int active;

  /// Cuántos pasos tiene el bloque (4 y 3).
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i <= active
                      ? AppColors.entryAccent
                      : AppColors.entryBorder,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Cuánto queda, en palabras: unos puntos de 6px no bastan, y decir en
        // qué bloque estás evita que el segundo se lea como una repetición.
        Text(
          'Block $block · Step $active of $count',
          style: const TextStyle(fontSize: 11, color: AppColors.entryHint),
        ),
      ],
    );
  }
}

/// Fuerza la mayúscula inicial del nombre. Solo toca el primer carácter, así
/// que la longitud no cambia y el cursor NO salta mientras se escribe.
class CapitalizeFirst extends TextInputFormatter {
  const CapitalizeFirst();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final fixed = newValue.text[0].toUpperCase() + newValue.text.substring(1);
    return fixed == newValue.text ? newValue : newValue.copyWith(text: fixed);
  }
}

/// Reflejo empático reactivo: cambia con la selección, con fade suave — Aura
/// responde, no interrumpe (SPEC V2 §3.1).
class Microcopy extends StatelessWidget {
  const Microcopy(this.text, {super.key});

  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          text!,
          key: ValueKey(text),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppTypography.serif,
            fontStyle: FontStyle.italic,
            fontSize: 13,
            height: 1.5,
            color: AppColors.entryHint,
          ),
        ),
      ),
    );
  }
}

/// Chip de momento con subtítulo (time-chip del maquetado v2).
class MomentChip extends StatelessWidget {
  const MomentChip({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.roseTint : const Color(0xFFF8F4FC),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.entryAccent : const Color(0xFFE8E0F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.entryAccent
                    : const Color(0xFF5A4F6A),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? AppColors.entryAccent.withValues(alpha: 0.55)
                    : AppColors.entryHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Cancel and start again ✕" del maquetado: borra las respuestas y vuelve al
/// primer paso de la frase (el paso 0 renace con el estado limpio).
class CancelLink extends ConsumerWidget {
  const CancelLink({super.key});

  /// Borra TODO lo respondido, así que pregunta. Antes bastaba un toque —y el
  /// enlace vive justo encima del botón primario, donde va el pulgar—, así que
  /// un roce en el último paso tiraba siete respuestas sin decir nada.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAuraConfirm(
      context,
      title: 'Start again?',
      message: "Everything you've told me so far will be cleared — your name, "
          'how you feel, all of it.',
      cancelLabel: 'Keep what I wrote',
      confirmLabel: 'Start again',
      // La entrada tiene su propio carmesí, más vivo que el de marca.
      accent: AppColors.entryAccent,
    );
    if (confirmed) {
      ref.read(onboardingControllerProvider.notifier).restart();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () => _confirm(context, ref),
      // Discreto a propósito: es una salida de emergencia, no una acción que
      // deba competir con "Continue".
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cancel and start again',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.entryHint,
            ),
          ),
          SizedBox(width: 6),
          Icon(CupertinoIcons.xmark, size: 11, color: AppColors.entryHint),
        ],
      ),
    );
  }
}
