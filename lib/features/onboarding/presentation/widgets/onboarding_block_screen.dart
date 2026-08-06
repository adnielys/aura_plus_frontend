import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/selectable_chip.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';
import 'feelings_modal.dart';
import 'onboarding_bits.dart';
import 'onboarding_card.dart';
import 'onboarding_fold.dart';
import 'onboarding_sentence.dart';
import 'onboarding_sheets.dart';
import 'pain_reflection.dart';

/// Un bloque del onboarding: sus pasos, sus puntos y su botón.
///
/// El contenido es exactamente el de siempre — mismas preguntas, mismos
/// controles, mismos reflejos. Lo único que cambia es dónde termina el
/// recorrido: en vez de enviar, el último paso PLIEGA la pantalla hasta
/// convertirla en su card.
class OnboardingBlockScreen extends ConsumerWidget {
  const OnboardingBlockScreen({super.key, required this.block});

  /// 1 = lo personal (nombre, edad, peques, sentimientos), 2 = el día.
  final int block;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final editing = ref.watch(editingSegmentProvider);

    // Esta pantalla dibuja SOLO los pasos de su bloque, aunque el estado ya
    // apunte a otro. Mientras sale deslizándose sigue viva y sigue leyendo el
    // provider: sin esto, la del bloque 1 se ponía a pintar el bloque 2 a la
    // vez que la que entra, montaba un segundo paso del día y su sheet se
    // abría DOS veces.
    final steps = block == 1 ? kBlock1Steps : kBlock2Steps;
    final step = steps.contains(state.stepIndex) ? state.stepIndex : steps.last;
    final stepInBlock = steps.indexOf(step) + 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OnboardingFold(
          folding: state.folding,
          onFolded: controller.closeBlock,
          // En lo que se convierte esta pantalla. Es la MISMA card que verá
          // después: si aquí se dibujara una imitación, el cambio de una a
          // otra se notaría justo en el fotograma en que aterriza.
          card: OnboardingCard(
            card: block,
            state: state,
            active: true,
            onTap: () {},
          ),
          child: Column(
            children: [
              // Sin flecha de volver: cualquier dato se corrige tocando su
              // palabra en la frase, y eso abre su control SIN mover el paso.
              const SizedBox(height: 28),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Padding(
                    key: ValueKey(step),
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                    // Scrollable SIN perder los Spacer: con varios sentimientos
                    // elegidos —o en una pantalla pequeña— desbordaba.
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: _StepContent(step: step),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // El pie ya no se funde aparte: se apaga con toda la pantalla,
              // porque lo que aparece encima es la card, no esta misma
              // pantalla encogida.
              StepDots(
                block: block,
                active: stepInBlock,
                count: steps.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                child: _BlockCta(
                  block: block,
                  step: step,
                  isLast: step == steps.last,
                  editing: editing != null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón del bloque. Tres estados: corrigiendo una palabra cierra la edición,
/// el último paso cierra la card, y el resto avanza.
/// Botón del bloque. Mira el paso de SU pantalla, no el del estado: mientras
/// la anterior se desliza fuera, el estado ya apunta a la siguiente y el botón
/// cambiaría de texto en plena salida.
class _BlockCta extends ConsumerWidget {
  const _BlockCta({
    required this.block,
    required this.step,
    required this.isLast,
    required this.editing,
  });

  final int block;
  final int step;
  final bool isLast;
  final bool editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Reeditando un dato, el botón CIERRA la edición y deja donde estabas; no
    // avanza. Antes tocar el nombre y confirmar te empujaba al paso siguiente.
    if (editing) {
      return SoftPrimaryButton(
        label: 'Done',
        onPressed: () =>
            ref.read(editingSegmentProvider.notifier).state = null,
      );
    }

    final answered = state.isStepAnswered(step);

    if (isLast) {
      return SoftPrimaryButton(
        // Dice lo que va a pasar, no "continuar": lo que sigue es ver cómo se
        // guarda lo que acabas de contar.
        label: block == 1 ? 'Close this card' : 'See both cards',
        onPressed: answered ? controller.startFold : null,
      );
    }

    return SoftPrimaryButton(
      label: 'Continue',
      onPressed: answered ? controller.next : null,
    );
  }
}

/// Selecciona el widget del paso actual. Los pasos 0–3 comparten la frase
/// continua, que se construye progresivamente (una línea por paso).
class _StepContent extends StatelessWidget {
  const _StepContent({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      // Dos párrafos acumulativos con el mismo cromo: el personal (nombre,
      // edad, peques, sentimiento) y el del día (lo que pesa, tiempo, momento).
      0 || 1 || 2 || 3 => _StepSentence(activeSegment: Segment.values[step]),
      _ => _ClosingStep(active: ClosingSegment.values[step - 4]),
    };
  }
}

// ── Pasos 1–4 · Frase continua progresiva (maquetado) ────────────────────────

class _StepSentence extends ConsumerStatefulWidget {
  const _StepSentence({required this.activeSegment});

  /// Segmento del paso actual: la frase muestra las líneas hasta este segmento
  /// (las anteriores ya respondidas, esta en edición) y su control debajo.
  final Segment activeSegment;

  @override
  ConsumerState<_StepSentence> createState() => _StepSentenceState();
}

class _StepSentenceState extends ConsumerState<_StepSentence> {
  late final TextEditingController _nameController;

  /// Edición desde el resumen (done): el párrafo COMPLETO se mantiene, solo la
  /// imagen cede su lugar al control del dato tocado (maquetado).

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: ref.read(onboardingControllerProvider).name);
    // Edad, peques y sentimientos abren su control AL ENTRAR: aparece listo,
    // sin un toque de más. Es seguro porque los tres tienen salida propia —los
    // sheets se arrastran o se cierran con "Done", el modal con su cruz—, así
    // que ninguno encierra. Para volver a ellos se toca su palabra en la frase.
    final opener = switch (widget.activeSegment) {
      Segment.age => _openAgeSheet,
      Segment.children => _openChildrenSheet,
      Segment.feeling => _openFeelingsModal,
      Segment.name => null, // se escribe en la propia línea
    };
    if (opener != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Ni plegando ni desde el bloque que ya no es el actual: esta pantalla
        // sigue viva mientras se desliza fuera, y su control quedaría abierto
        // encima de la que llega.
        final state = ref.read(onboardingControllerProvider);
        if (state.folding || state.block != 1) return;
        opener();
      });
    }
  }

  /// Campo del nombre DENTRO de la línea (maquetado: se escribe en la frase).
  /// Compartido por el paso inicial y la edición desde el resumen.
  Widget _inlineNameRow(TextStyle serif) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 170),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              textAlign: TextAlign.center,
              maxLength: 50,
              cursorColor: AppColors.entryAccent,
              // El teclado propone mayúscula y el formatter la GARANTIZA:
              // el nombre es cómo Aura la llama, y en minúscula se lee como
              // un descuido, no como una elección.
              textCapitalization: TextCapitalization.words,
              inputFormatters: const [CapitalizeFirst()],
              // Se escribe YA con el estilo que tendrá en la frase (carmesí
              // bold, sin itálica): antes cambiaba de aspecto al confirmar y
              // parecía otra cosa mientras lo tecleabas.
              style: serif.copyWith(
                color: AppColors.entryAccent,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.normal,
              ),
              onChanged:
                  ref.read(onboardingControllerProvider.notifier).setName,
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'your name',
                hintStyle: serif.copyWith(
                  color: AppColors.entryPlaceholder,
                  fontStyle: FontStyle.italic,
                ),
                contentPadding: const EdgeInsets.only(bottom: 2),
                enabledBorder: const UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.entryPlaceholder, width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.entryAccent.withValues(alpha: 0.55),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(',', style: serif),
      ],
    );
  }

  Future<void> _openFeelingsModal() {
    return showGeneralDialog(
      context: context,
      // Se puede salir sin elegir: el modal trae su propio "atrás" y el gesto
      // del sistema funciona. barrierLabel es OBLIGATORIO si barrierDismissible
      // es true — sin él Flutter lanza una aserción y el modal ni se abre.
      barrierDismissible: true,
      barrierLabel: 'Close',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
      pageBuilder: (_, _, _) => const FeelingsModal(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    // Estado "done" del maquetado: elegido el sentimiento, aparece el resumen
    // (cabecera + imagen + frase completa). Antes, cada paso muestra SOLO su
    // línea y se escribe en la propia línea.
    final done =
        widget.activeSegment == Segment.feeling && state.feelings.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: done
              ? SingleChildScrollView(child: _doneSummary(state))
              : _singleLineStep(state),
        ),
        const CancelLink(),
      ],
    );
  }

  /// Paso de la frase (distribución del maquetado): el párrafo arriba —las
  /// líneas ya respondidas quedan visibles— y el control del paso ANCLADO
  /// abajo, junto al CTA. La línea nueva entra con riseIn.
  Widget _singleLineStep(OnboardingState state) {
    final control = _lineControl(state);
    return Column(
      children: [
        const SizedBox(height: 40),
        for (final segment in Segment.values)
          if (segment.index < widget.activeSegment.index)
            _staticLine(state, segment),
        TweenAnimationBuilder<double>(
          key: ValueKey(widget.activeSegment),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          ),
          child: _activeLine(state),
        ),
        const Spacer(),
        // Edad y peques no dejan nada aquí: el control, el porqué y el "Skip"
        // viven DENTRO de su bottom sheet. Se reabre tocando el valor en la
        // frase, así que el paso queda limpio.
        if (control != null)
          TweenAnimationBuilder<double>(
            key: ValueKey('ctrl-${widget.activeSegment}'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: control,
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Línea ya respondida del párrafo (valor en magenta, sin subrayado).
  Widget _staticLine(OnboardingState state, Segment segment) {
    final serif = Theme.of(context)
        .textTheme
        .displaySmall!
        .copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w400,
          height: 1.3,
          // Gris cálido de la frase (--text-main del maquetado).
          color: AppColors.entryInk,
        );

    TextSpan value(String? text, String placeholder) => TextSpan(
          text: text ?? placeholder,
          style: serif.copyWith(
            color: text == null ? AppColors.entryPlaceholder : AppColors.entryAccent,
            fontWeight: text == null ? FontWeight.w400 : FontWeight.w700,
            fontStyle: text == null ? FontStyle.italic : FontStyle.normal,
          ),
        );

    // Volver a un dato ya respondido: cada uno abre SU sheet o su modal, y
    // ninguno mueve el paso — así la frase de detrás nunca pierde líneas.
    // (El nombre hacía goToStep(0) y borraba todo lo posterior.)
    Widget tappable(Segment target, Widget child) => GestureDetector(
          onTap: () => switch (target) {
            // El nombre NO abre sheet: su línea se convierte en el campo y
            // sale el teclado. Se escribe en la frase, que es la gracia.
            Segment.name => _startEditingName(),
            Segment.age => _openAgeSheet(),
            Segment.children => _openChildrenSheet(),
            Segment.feeling => _openFeelingsModal(),
          },
          behavior: HitTestBehavior.opaque,
          child: child,
        );

    // El nombre ocupa SU PROPIA línea bajo "My name is" (saltos del maquetado).
    // Al tocarlo, esa línea SE CONVIERTE en el campo: solo teclado, sin sheet.
    if (segment == Segment.name) {
      final editing = ref.watch(editingSegmentProvider) == Segment.name;
      final line = Column(
        children: [
          Text('My name is', textAlign: TextAlign.center, style: serif),
          if (editing)
            _inlineNameRow(serif)
          else
            Text.rich(
              TextSpan(children: [
                value(
                  state.name.trim().isEmpty ? null : state.name.trim(),
                  'your name',
                ),
                TextSpan(text: ',', style: serif),
              ]),
              textAlign: TextAlign.center,
            ),
        ],
      );
      // Mientras se edita no se envuelve en el GestureDetector: taparía los
      // toques del propio campo (mover el cursor, seleccionar).
      return editing ? line : tappable(Segment.name, line);
    }

    final spans = switch (segment) {
      Segment.name => <TextSpan>[],
      Segment.age => [
          TextSpan(text: 'I am ', style: serif),
          value(state.age?.toString(), '··'),
          TextSpan(text: ' years old', style: serif),
        ],
      Segment.children => [
          TextSpan(text: 'with ', style: serif),
          value(state.childrenCount?.toString(), '··'),
          TextSpan(
            text: (state.childrenCount ?? 2) == 1 ? ' child' : ' children',
            style: serif,
          ),
        ],
      Segment.feeling => <TextSpan>[],
    };

    return tappable(
      segment,
      Text.rich(TextSpan(children: spans), textAlign: TextAlign.center),
    );
  }

  /// La línea del paso actual, en serif grande y centrada.
  Widget _activeLine(OnboardingState state) {
    final serif = Theme.of(context)
        .textTheme
        .displaySmall!
        .copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w400,
          height: 1.3,
          // Gris cálido de la frase (--text-main del maquetado).
          color: AppColors.entryInk,
        );

    TextSpan value(String? text, String placeholder) => TextSpan(
          text: text ?? placeholder,
          style: serif.copyWith(
            color: text == null ? AppColors.entryPlaceholder : AppColors.entryAccent,
            fontWeight: text == null ? FontWeight.w400 : FontWeight.w700,
            fontStyle: text == null ? FontStyle.italic : FontStyle.normal,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.entryAccent.withValues(alpha: 0.4),
            decorationThickness: 1.5,
          ),
        );

    return switch (widget.activeSegment) {
      // El nombre se escribe DENTRO de la línea (campo inline subrayado).
      Segment.name => Column(
          children: [
            Text('My name is', textAlign: TextAlign.center, style: serif),
            _inlineNameRow(serif),
          ],
        ),
      // Tocar la línea reabre el sheet: es la única forma de volver a él una
      // vez cerrado, y el subrayado del valor ya invita a tocarlo.
      Segment.age => GestureDetector(
          onTap: _openAgeSheet,
          behavior: HitTestBehavior.opaque,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'I am ', style: serif),
              value(state.age?.toString(), '··'),
              TextSpan(text: ' years old', style: serif),
            ]),
            textAlign: TextAlign.center,
          ),
        ),
      Segment.children => GestureDetector(
          onTap: _openChildrenSheet,
          behavior: HitTestBehavior.opaque,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'with ', style: serif),
              value(state.childrenCount?.toString(), '··'),
              TextSpan(
                text: (state.childrenCount ?? 2) == 1 ? ' child' : ' children',
                style: serif,
              ),
            ]),
            textAlign: TextAlign.center,
          ),
        ),
      // Tocar la palabra reabre el modal: es la única vía tras cerrarlo, ya
      // que bajo la frase no queda ningún botón.
      Segment.feeling => GestureDetector(
          onTap: _openFeelingsModal,
          behavior: HitTestBehavior.opaque,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'I feel ', style: serif),
              value(
                state.feelings.isEmpty ? null : joinFeelings(state.feelings),
                'like this',
              ),
              TextSpan(text: '.', style: serif),
            ]),
            textAlign: TextAlign.center,
          ),
        ),
    };
  }

  /// Ningún paso deja control suelto bajo la frase: cada dato vive en su sheet
  /// o en su modal, que se abre al entrar al paso y se reabre tocando su
  /// palabra. El nombre se escribe en la propia línea.
  Widget? _lineControl(OnboardingState state) => null;

  /// Bottom sheet de peques: número y edades, con su propia salida.
  /// Bottom sheet del nombre (solo para reeditarlo: en su paso se escribe en
  /// la propia línea de la frase).
  /// Editar el nombre: su línea de la frase pasa a ser el campo (con teclado),
  /// sin sheet y sin mover el paso.
  void _startEditingName() {
    _nameController.text = ref.read(onboardingControllerProvider).name;
    ref.read(editingSegmentProvider.notifier).state = Segment.name;
  }

  Future<void> _openChildrenSheet() => _openSheet(const ChildrenSheet());

  /// Bottom sheet de la edad.
  Future<void> _openAgeSheet() => _openSheet(const AgeSheet());

  Future<void> _openSheet(Widget child) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => child,
    );
  }

  /// Estado final del maquetado (#onboarding.done): cabecera + imagen + frase
  /// completa con las emociones DENTRO de la frase (sin chips). "Tap any word
  /// to edit it": el párrafo entero se MANTIENE; solo la imagen desaparece
  /// para dar lugar al control del dato tocado (la de sentimientos reabre el
  /// modal, que también conserva el texto al volver).
  Widget _doneSummary(OnboardingState state) {
    final editing = ref.watch(editingSegmentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Eyebrow del maquetado: GFS Didot espaciada.
        const Center(
          child: Text('THIS IS HOW YOU FEEL', style: AppTypography.eyebrow),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Tap any word to edit it',
            style: TextStyle(fontSize: 12, color: AppColors.entryHint),
          ),
        ),
        const SizedBox(height: 14),
        // Solo la imagen cede su lugar al control (maquetado).
        if (editing == null)
          Center(
            child: Image.asset(
              blockImage(1),
              height: 215,
              fit: BoxFit.contain,
            ),
          ),
        const SizedBox(height: 14),
        Sentence(
          state: state,
          active: editing ?? widget.activeSegment,
          showAll: true,
          // El nombre se edita EN su línea; numéricos en su componente debajo.
          nameEditor: editing == Segment.name
              ? _inlineNameRow(Theme.of(context).textTheme.displaySmall!
                  .copyWith(
                    fontSize: 33,
                    fontWeight: FontWeight.w400,
                    height: 1.36,
                    color: AppColors.entryInk,
                  ))
              : null,
          // Tocar una palabra abre DIRECTAMENTE su control: el nombre se
          // escribe en su línea (solo teclado), edad y peques en su bottom
          // sheet y los sentimientos en su modal. Ninguno mueve el paso, así la
          // frase de detrás se queda entera.
          onLineTap: (segment) {
            switch (segment) {
              case Segment.name:
                _startEditingName();
              case Segment.age:
                _openAgeSheet();
              case Segment.children:
                _openChildrenSheet();
              case Segment.feeling:
                _openFeelingsModal();
            }
          },
        ),
        // Solo el nombre entra en modo edición aquí (se escribe en su propia
        // línea); edad, peques y sentimientos abren su sheet o su modal.
        if (editing != null)
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(editingSegmentProvider.notifier).state = null,
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

}

// ── Pasos 5–7 · frase en primera persona (mezcla v2, aprobada) ───────────────

/// Andamio de los pasos finales: la frase arriba con el valor tejido en
/// carmesí, el control anclado abajo con su microcopy empático, y el enlace
/// de cancelar — misma distribución que los pasos de la frase personal.
/// Los tres datos del cierre; su orden es el de los pasos 4–6.
enum ClosingSegment { pain, time, moment }

/// Bloque de cierre (pasos 5–7): SEGUNDO párrafo acumulativo, con el mismo
/// cromo que el personal — rótulo, ilustración y la frase creciendo línea a
/// línea. Antes cada uno era una frase suelta sin cabecera ni imagen, y el
/// flujo se partía en dos: se sentía como otro formulario.
class _ClosingStep extends ConsumerStatefulWidget {
  const _ClosingStep({required this.active});

  final ClosingSegment active;

  @override
  ConsumerState<_ClosingStep> createState() => _ClosingStepState();
}

class _ClosingStepState extends ConsumerState<_ClosingStep> {
  @override
  void initState() {
    super.initState();
    // Igual que el resto: el control aparece al entrar y no cuelga bajo la
    // frase. Se vuelve a él tocando la palabra.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Misma regla que en el bloque 1: ni plegando ni desde un bloque que ya
      // no es el actual, o el sheet acaba abierto sobre la vista siguiente.
      final state = ref.read(onboardingControllerProvider);
      if (state.folding || state.block != 2) return;
      _openSheet(widget.active);
    });
  }

  Future<void> _openSheet(ClosingSegment segment) =>
      openClosingSheet(context, ref, segment);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    // Misma tipografía que el párrafo personal (era 28 y se notaba el salto).
    final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 33,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: AppColors.entryInk,
        );

    TextSpan value(String? text, String placeholder) => TextSpan(
          text: text ?? placeholder,
          style: serif.copyWith(
            color:
                text == null ? AppColors.entryPlaceholder : AppColors.entryAccent,
            fontWeight: text == null ? FontWeight.w400 : FontWeight.w700,
            fontStyle: text == null ? FontStyle.italic : FontStyle.normal,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.entryAccent.withValues(alpha: 0.4),
            decorationThickness: 1.5,
          ),
        );

    /// Una línea del párrafo. Las posteriores al paso actual aún no existen.
    Widget line(ClosingSegment segment, List<InlineSpan> spans) {
      if (segment.index > widget.active.index) return const SizedBox.shrink();
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        builder: (context, v, child) => Opacity(opacity: v, child: child),
        // Tocar la línea reabre SU sheet, sin mover el paso.
        child: GestureDetector(
          onTap: () => _openSheet(segment),
          behavior: HitTestBehavior.opaque,
          child: Text.rich(
            TextSpan(children: spans),
            textAlign: TextAlign.center,
            style: serif,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Text('AND THIS IS YOUR DAY', style: AppTypography.eyebrow),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Tap any word to edit it',
            style: TextStyle(fontSize: 12, color: AppColors.entryHint),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Image.asset(
            blockImage(2),
            height: 215,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
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
        const Spacer(),
        const CancelLink(),
      ],
    );
  }
}

/// Chips con subtítulo (maquetado v2).
const _momentSubLabel = {
  PreferredMoment.earlyMorning: 'before the noise',
  PreferredMoment.morning: 'once the day has started',
  PreferredMoment.midday: 'a pause in the middle',
  PreferredMoment.night: 'when the kids sleep',
};

const _momentShortLabel = {
  PreferredMoment.earlyMorning: 'Early morning',
  PreferredMoment.morning: 'Mid-morning',
  PreferredMoment.midday: 'Midday',
  PreferredMoment.night: 'Night',
};

/// Contrato emocional (SPEC_CONTENIDO_EMOCIONAL_V2 §3.2): estado de éxito del
/// onboarding. Sin metas ni presión — cierra el arco de entrada. La usuaria

/// Abre el sheet de un dato del día. Es una función de nivel superior y no
/// un método porque la usan DOS pantallas: el paso del bloque 2 y la card
/// abierta a corregir. Con una copia en cada sitio, cambiar un chip dejaría
/// la edición preguntando otra cosa.
Future<void> openClosingSheet(
  BuildContext context,
  WidgetRef ref,
  ClosingSegment segment,
) {
  final controller = ref.read(onboardingControllerProvider.notifier);
  final (title, control, microcopy) = switch (segment) {
    ClosingSegment.pain => (
        'What weighs on you most?',
        // Consumer: los chips viven en el sheet y deben seguir reaccionando;
        // un widget ya construido se quedaría congelado al elegir.
        Consumer(builder: (context, ref, _) {
          final chosen = ref
              .watch(onboardingControllerProvider.select((s) => s.mainPain));
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final pain in MainPain.values)
                SelectableChip(
                  label: pain.label,
                  selected: chosen == pain,
                  onTap: () => controller.setMainPain(pain),
                ),
            ],
          );
        }),
        Consumer(builder: (context, ref, _) {
          final chosen = ref
              .watch(onboardingControllerProvider.select((s) => s.mainPain));
          return Microcopy(chosen == null ? null : painReflections[chosen]);
        }),
      ),
    ClosingSegment.time => (
        'How much time do you have each day?',
        Consumer(builder: (context, ref, _) {
          final chosen = ref.watch(
              onboardingControllerProvider.select((s) => s.dailyTimeSlot));
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final slot in TimeSlot.values)
                SelectableChip(
                  label: slot.label,
                  selected: chosen == slot,
                  onTap: () => controller.setTimeSlot(slot),
                ),
            ],
          );
        }),
        // Anti-vergüenza REACTIVA: valida el número que ELLA dijo — jamás un
        // benchmark que deje corta una opción (textos aprobados jul 2026).
        Consumer(builder: (context, ref, _) {
          final chosen = ref.watch(
              onboardingControllerProvider.select((s) => s.dailyTimeSlot));
          return Microcopy(chosen == null
              ? timeReflectionDefault
              : timeReflections[chosen]);
        }),
      ),
    ClosingSegment.moment => (
        'When is your moment?',
        Consumer(builder: (context, ref, _) {
          final chosen = ref.watch(
              onboardingControllerProvider.select((s) => s.preferredMoment));
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final moment in PreferredMoment.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MomentChip(
                    title: _momentShortLabel[moment]!,
                    subtitle: _momentSubLabel[moment]!,
                    selected: chosen == moment,
                    onTap: () => controller.setMoment(moment),
                  ),
                ),
            ],
          );
        }),
        // La promesa del producto (1 mensaje/día) es idéntica en las 4
        // opciones; solo se tiñe del momento elegido (aprobados jul 2026).
        Consumer(builder: (context, ref, _) {
          final chosen = ref.watch(
              onboardingControllerProvider.select((s) => s.preferredMoment));
          return Microcopy(chosen == null
              ? momentReflectionDefault
              : momentReflections[chosen]);
        }),
      ),
  };

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) =>
        ChoiceSheet(title: title, control: control, microcopy: microcopy),
  );
}
