import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/enums.dart';
import '../providers/onboarding_controller.dart';

/// La frase continua del onboarding y su vocabulario de segmentos. Salió de
/// onboarding_screen.dart sin tocarle el comportamiento.

/// Segmentos de la frase; su orden es el de los pasos 0–3.
enum Segment { name, age, children, feeling }

/// Dato que se está reeditando desde la frase (null = ninguno).
///
/// Vive FUERA del State porque el botón primario está en la pantalla y tiene
/// que saberlo: mientras se edita, ese botón cierra la edición y NO avanza de
/// paso. Si no, tocar el nombre y confirmar te empujaba al paso siguiente en
/// vez de devolverte donde estabas.
final editingSegmentProvider = StateProvider<Segment?>((ref) => null);

/// La frase continua en serif, construida PROGRESIVAMENTE (maquetado): solo se
/// muestran las líneas ya respondidas y la del paso actual, que aparece con un
/// fundido suave. El valor va en bold magenta; si falta, placeholder rosado.
class Sentence extends StatelessWidget {
  const Sentence({
    super.key,
    required this.state,
    required this.active,
    this.onLineTap,
    this.showAll = false,
    this.nameEditor,
  });

  final OnboardingState state;
  final Segment active;

  /// "Tap any word to edit it" (maquetado): tocar una línea vuelve a su paso.
  final ValueChanged<Segment>? onLineTap;

  /// En el resumen (done) el párrafo COMPLETO se mantiene siempre visible,
  /// aunque se esté editando una línea anterior.
  final bool showAll;

  /// Editor inline del nombre: al editarlo desde el resumen, la línea del
  /// nombre se convierte en el campo (se escribe en la frase, no debajo).
  final Widget? nameEditor;

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context)
        .textTheme
        .displaySmall!
        .copyWith(
          fontSize: 33,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: AppColors.entryInk,
        );

    TextSpan value(String? text, String placeholder, Segment segment) {
      final missing = text == null;
      return TextSpan(
        text: missing ? placeholder : text,
        style: serif.copyWith(
          color: missing ? AppColors.entryPlaceholder : AppColors.entryAccent,
          fontWeight: missing ? FontWeight.w400 : FontWeight.w700,
          fontStyle: missing ? FontStyle.italic : FontStyle.normal,
          decoration:
              segment == active ? TextDecoration.underline : TextDecoration.none,
          decorationColor: AppColors.entryAccent.withValues(alpha: 0.4),
          decorationThickness: 1.5,
        ),
      );
    }

    final name = state.name.trim().isEmpty ? null : state.name.trim();
    final age = state.age?.toString();
    final children = state.childrenCount?.toString();
    final feeling = joinFeelings(state.feelings);

    Widget line(Segment segment, Widget child, {bool tappable = true}) {
      // Progresivo: las líneas posteriores al paso actual aún no existen; la
      // nueva entra con fadeSoft (el tween corre al insertarse en el árbol).
      // En el resumen (showAll) nunca se ocultan.
      if (!showAll && segment.index > active.index) {
        return const SizedBox.shrink();
      }
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: onLineTap == null || !tappable
            ? child
            : GestureDetector(onTap: () => onLineTap!(segment), child: child),
      );
    }

    Text rich(List<TextSpan> spans) => Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.center,
          style: serif,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // El nombre en SU PROPIA línea (saltos del maquetado). Si se está
        // editando, la línea ES el campo inline (no un input aparte).
        line(
          Segment.name,
          Column(
            children: [
              Text('My name is', textAlign: TextAlign.center, style: serif),
              nameEditor ??
                  rich([
                    value(name, 'your name', Segment.name),
                    TextSpan(text: ',', style: serif),
                  ]),
            ],
          ),
          tappable: nameEditor == null,
        ),
        line(
          Segment.age,
          rich([
            TextSpan(text: 'I am ', style: serif),
            value(age, '··', Segment.age),
            TextSpan(text: ' years old', style: serif),
          ]),
        ),
        line(
          Segment.children,
          rich([
            TextSpan(text: 'with ', style: serif),
            value(children, '··', Segment.children),
            TextSpan(
              text: (state.childrenCount ?? 2) == 1 ? ' child' : ' children',
              style: serif,
            ),
          ]),
        ),
        line(
          Segment.feeling,
          rich([
            TextSpan(text: 'I feel ', style: serif),
            value(feeling, 'like this', Segment.feeling),
            TextSpan(text: '.', style: serif),
          ]),
        ),
      ],
    );
  }
}

/// "agotada", "agotada y sola", "agotada, sola y culpable" (para la frase).
String? joinFeelings(List<Feeling> feelings) {
  if (feelings.isEmpty) return null;
  final labels = [for (final f in feelings) f.label.toLowerCase()];
  if (labels.length == 1) return labels.single;
  return '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}';
}

/// Cómo se lee cada elección dentro del párrafo de cierre.
const painValue = {
  MainPain.work: 'work',
  MainPain.family: 'my family and home',
  MainPain.self: 'myself',
  MainPain.relationships: 'my relationships',
  MainPain.all: 'everything at once',
};

const timeValue = {
  TimeSlot.minimal: '5 minutes',
  TimeSlot.short: '10–20 minutes',
  TimeSlot.medium: '30+ minutes',
};

const momentValue = {
  PreferredMoment.earlyMorning: 'early, before the noise',
  PreferredMoment.morning: 'mid-morning',
  PreferredMoment.midday: 'at midday',
  PreferredMoment.night: 'at night, when they sleep',
};
