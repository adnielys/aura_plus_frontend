import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';
import 'feelings_modal.dart';
import 'onboarding_block_screen.dart';
import 'onboarding_bits.dart';
import 'onboarding_sentence.dart';
import 'onboarding_sheets.dart';

/// Una card abierta a pantalla completa para corregirla.
///
/// Aquí los controles NO se abren solos, al revés que en el flujo de pasos.
/// Allí venías a responder y encontrártelo abierto ahorra un toque; aquí
/// vienes a cambiar UNA palabra, y que se te abra un sheet encima de la frase
/// que querías leer es justo lo contrario de lo que buscabas.
class OnboardingEditScreen extends ConsumerStatefulWidget {
  const OnboardingEditScreen({super.key});

  @override
  ConsumerState<OnboardingEditScreen> createState() =>
      _OnboardingEditScreenState();
}

class _OnboardingEditScreenState extends ConsumerState<OnboardingEditScreen> {
  // En initState y NO en un `late final`: si la pantalla se cierra sin haber
  // tocado el nombre, el campo seguiría sin crear y dispose() lo estrenaría
  // justo cuando `ref` ya no vale. Cazado en test, revienta igual en la app.
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(onboardingControllerProvider).name,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _openSheet(Widget child) => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => child,
      );

  void _tapPersonal(Segment segment) {
    switch (segment) {
      case Segment.name:
        ref.read(editingSegmentProvider.notifier).state = Segment.name;
      case Segment.age:
        _openSheet(const AgeSheet());
      case Segment.children:
        _openSheet(const ChildrenSheet());
      case Segment.feeling:
        Navigator.of(context).push(PageRouteBuilder<void>(
          opaque: true,
          pageBuilder: (_, _, _) => const FeelingsModal(),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final card = state.editingCard;
    final editingName = ref.watch(editingSegmentProvider) == Segment.name;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Text(
              card == 1 ? 'THIS IS HOW YOU FEEL' : 'AND THIS IS YOUR DAY',
              style: const TextStyle(
                fontFamily: AppTypography.didot,
                fontSize: 13,
                letterSpacing: 2,
                color: AppColors.entryHint,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap any word to edit it',
              style: TextStyle(fontSize: 12, color: AppColors.entryHint),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: card == 1
                            ? Sentence(
                                state: state,
                                // showAll: el párrafo entero se queda; esto no
                                // es un recorrido, es una corrección.
                                showAll: true,
                                active: Segment.feeling,
                                onLineTap: _tapPersonal,
                                nameEditor:
                                    editingName ? _inlineName(context) : null,
                              )
                            : _DaySentence(state: state),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Card $card of 2',
              style: const TextStyle(fontSize: 11, color: AppColors.entryHint),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              // Escribiendo el nombre, el botón CIERRA el campo y te deja
              // donde estabas; no guarda la card. Guardar con el teclado
              // delante y la frase a medio leer es cerrar algo que todavía no
              // habías terminado de mirar. Es la misma regla que en los pasos.
              child: editingName
                  ? SoftPrimaryButton(
                      label: 'Done',
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        ref.read(editingSegmentProvider.notifier).state = null;
                      },
                    )
                  : SoftPrimaryButton(
                      label: 'Save',
                      // Mismas reglas que el flujo: una card no se guarda a
                      // medias, pero el botón apagado lo dice sin regañar.
                      onPressed:
                          state.isBlockComplete(card) ? controller.saveCard : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// El nombre se corrige DENTRO de la frase, como cuando se escribió.
  Widget _inlineName(BuildContext context) {
    final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 33,
          fontWeight: FontWeight.w700,
          color: AppColors.entryAccent,
        );
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 170),
        child: TextField(
          controller: _name,
          autofocus: true,
          textAlign: TextAlign.center,
          cursorColor: AppColors.entryAccent,
          textCapitalization: TextCapitalization.words,
          inputFormatters: const [CapitalizeFirst()],
          style: serif,
          onChanged:
              ref.read(onboardingControllerProvider.notifier).setName,
          decoration: const InputDecoration(
            isDense: true,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.entryPlaceholder),
            ),
          ),
        ),
      ),
    );
  }
}

/// La frase del día, a tamaño de pantalla y con sus tres palabras tocables.
class _DaySentence extends ConsumerWidget {
  const _DaySentence({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 33,
          fontWeight: FontWeight.w400,
          height: 1.36,
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

    Widget line(ClosingSegment segment, List<InlineSpan> spans) =>
        GestureDetector(
          onTap: () => openClosingSheet(context, ref, segment),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text.rich(
              TextSpan(children: spans),
              textAlign: TextAlign.center,
              style: serif,
            ),
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(ClosingSegment.pain, [
          TextSpan(text: 'Right now, the hardest part is ', style: serif),
          value(painValue[state.mainPain], 'this'),
          TextSpan(text: '.', style: serif),
        ]),
        line(ClosingSegment.time, [
          TextSpan(text: 'Each day, I have about ', style: serif),
          value(timeValue[state.dailyTimeSlot], 'some time'),
          TextSpan(text: ' for myself.', style: serif),
        ]),
        line(ClosingSegment.moment, [
          TextSpan(text: 'My Aura+ moment is ', style: serif),
          value(momentValue[state.preferredMoment], 'yours to choose'),
          TextSpan(text: '.', style: serif),
        ]),
      ],
    );
  }
}
