import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/selectable_chip.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';

/// Flujo de onboarding (maquetado `aura_preview`): la frase continua reúne lo
/// personal (nombre, edad, peques, sentimiento) en un solo paso editable por
/// segmentos; después dolor → tiempo → momento. El estado vive en el
/// [OnboardingController]; al completar, el router redirige a Home.
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

    // Tras enviar con éxito: contrato emocional (SPEC V2 §3.2), no más pasos.
    if (state.completed) {
      return _EmotionalContract(
        name: state.name.trim(),
        onEnter: controller.enterSpace,
      );
    }

    return Scaffold(
      // Zona de entrada del maquetado: fondo blanco puro.
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              canGoBack: state.stepIndex > 0 && !state.isSubmitting,
              onBack: controller.back,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  key: ValueKey(state.stepIndex),
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                  child: _StepContent(step: state.stepIndex),
                ),
              ),
            ),
            _StepDots(active: state.stepIndex),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: SoftPrimaryButton(
                label: state.isLastStep ? 'Start with Aura+' : 'Continue',
                onPressed: state.canContinue
                    ? (state.isLastStep ? controller.submit : controller.next)
                    : null,
                isLoading: state.isSubmitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra superior mínima: solo una flecha para volver un paso (UX_01: sin
/// acciones que compitan con el CTA).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.canGoBack, required this.onBack});

  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: AppColors.textSecondary,
                onPressed: onBack,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Puntos de progreso: el paso activo se alarga en magenta (como el maquetado).
class _StepDots extends StatelessWidget {
  const _StepDots({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < kOnboardingSteps; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i <= active ? AppColors.entryAccent : AppColors.entryBorder,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
      ],
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
      0 || 1 || 2 || 3 => _StepSentence(activeSegment: _Segment.values[step]),
      4 => const _StepMainPain(),
      5 => const _StepTime(),
      _ => const _StepMoment(),
    };
  }
}

// ── Pasos 1–4 · Frase continua progresiva (maquetado) ────────────────────────

/// Segmentos de la frase; su orden es el de los pasos 0–3.
enum _Segment { name, age, children, feeling }

class _StepSentence extends ConsumerStatefulWidget {
  const _StepSentence({required this.activeSegment});

  /// Segmento del paso actual: la frase muestra las líneas hasta este segmento
  /// (las anteriores ya respondidas, esta en edición) y su control debajo.
  final _Segment activeSegment;

  @override
  ConsumerState<_StepSentence> createState() => _StepSentenceState();
}

class _StepSentenceState extends ConsumerState<_StepSentence> {
  late final TextEditingController _nameController;

  /// Edición desde el resumen (done): el párrafo COMPLETO se mantiene, solo la
  /// imagen cede su lugar al control del dato tocado (maquetado).
  _Segment? _editSegment;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: ref.read(onboardingControllerProvider).name);
    // Transición del maquetado: al llegar al paso del sentimiento, el selector
    // se abre solo como modal a pantalla completa.
    if (widget.activeSegment == _Segment.feeling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(onboardingControllerProvider).feelings.isEmpty) {
          _openFeelingsModal();
        }
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
              // Mientras se edita: itálica regular (seg-val.editing del
              // maquetado). El bold llega al confirmar la línea.
              style: serif.copyWith(
                color: AppColors.entryAccent,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
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
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
      pageBuilder: (_, _, _) => const _FeelingsModal(),
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
        widget.activeSegment == _Segment.feeling && state.feelings.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: done
              ? SingleChildScrollView(child: _doneSummary(state))
              : _singleLineStep(state),
        ),
        const _CancelLink(),
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
        for (final segment in _Segment.values)
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
  Widget _staticLine(OnboardingState state, _Segment segment) {
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

    // El nombre ocupa SU PROPIA línea bajo "My name is" (saltos del maquetado).
    if (segment == _Segment.name) {
      return Column(
        children: [
          Text('My name is', textAlign: TextAlign.center, style: serif),
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
    }

    final spans = switch (segment) {
      _Segment.name => <TextSpan>[],
      _Segment.age => [
          TextSpan(text: 'I am ', style: serif),
          value(state.age?.toString(), '··'),
          TextSpan(text: ' years old', style: serif),
        ],
      _Segment.children => [
          TextSpan(text: 'with ', style: serif),
          value(state.childrenCount?.toString(), '··'),
          TextSpan(
            text: (state.childrenCount ?? 2) == 1 ? ' child' : ' children',
            style: serif,
          ),
        ],
      _Segment.feeling => <TextSpan>[],
    };

    return Text.rich(TextSpan(children: spans), textAlign: TextAlign.center);
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
      _Segment.name => Column(
          children: [
            Text('My name is', textAlign: TextAlign.center, style: serif),
            _inlineNameRow(serif),
          ],
        ),
      _Segment.age => Text.rich(
          TextSpan(children: [
            TextSpan(text: 'I am ', style: serif),
            value(state.age?.toString(), '··'),
            TextSpan(text: ' years old', style: serif),
          ]),
          textAlign: TextAlign.center,
        ),
      _Segment.children => Text.rich(
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
      _Segment.feeling => Text.rich(
          TextSpan(children: [
            TextSpan(text: 'I feel like ', style: serif),
            value(null, 'this'),
            TextSpan(text: '.', style: serif),
          ]),
          textAlign: TextAlign.center,
        ),
    };
  }

  /// Control bajo la línea (solo cuando el dato no se escribe en la línea).
  Widget? _lineControl(OnboardingState state) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    return switch (widget.activeSegment) {
      _Segment.name => null, // se escribe en la propia línea
      _Segment.age => _Stepper(
          value: state.age,
          placeholder: "I'd rather not say",
          min: 16,
          max: 99,
          initial: 25, // punto de partida del maquetado
          onChanged: controller.setAge,
        ),
      _Segment.children => _ChildrenControl(state: state),
      _Segment.feeling => TextButton(
          onPressed: _openFeelingsModal,
          child: const Text(
            'Choose how I feel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
    };
  }

  /// Estado final del maquetado (#onboarding.done): cabecera + imagen + frase
  /// completa con las emociones DENTRO de la frase (sin chips). "Tap any word
  /// to edit it": el párrafo entero se MANTIENE; solo la imagen desaparece
  /// para dar lugar al control del dato tocado (la de sentimientos reabre el
  /// modal, que también conserva el texto al volver).
  Widget _doneSummary(OnboardingState state) {
    final editing = _editSegment;

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
              'assets/images/onboarding/feelings-header.png',
              height: 170,
              fit: BoxFit.contain,
            ),
          ),
        const SizedBox(height: 14),
        _Sentence(
          state: state,
          active: editing ?? widget.activeSegment,
          showAll: true,
          // El nombre se edita EN su línea; numéricos en su componente debajo.
          nameEditor: editing == _Segment.name
              ? _inlineNameRow(Theme.of(context).textTheme.displaySmall!
                  .copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    height: 1.36,
                    color: AppColors.entryInk,
                  ))
              : null,
          onLineTap: (segment) {
            if (segment == _Segment.feeling) {
              _openFeelingsModal();
            } else {
              _nameController.text = state.name;
              setState(() => _editSegment = segment);
            }
          },
        ),
        if (editing != null) ...[
          const SizedBox(height: 22),
          TweenAnimationBuilder<double>(
            key: ValueKey('edit-$editing'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: _editControl(state, editing),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _editSegment = null),
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
      ],
    );
  }

  /// Control de edición dentro del resumen (el texto no se pierde). El nombre
  /// no tiene control aquí: se edita inline en su línea de la frase.
  Widget _editControl(OnboardingState state, _Segment segment) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    return switch (segment) {
      _Segment.name => const SizedBox.shrink(),
      _Segment.age => _Stepper(
          value: state.age,
          placeholder: "I'd rather not say",
          min: 16,
          max: 99,
          initial: 25,
          onChanged: controller.setAge,
        ),
      _Segment.children => _ChildrenControl(state: state),
      _Segment.feeling => const SizedBox.shrink(),
    };
  }
}

/// Modal del maquetado (feel-modal): pantalla completa con título serif, grid
/// de 3 columnas con ilustraciones y "Listo". Multi-selección.
class _FeelingsModal extends ConsumerWidget {
  const _FeelingsModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feelings = ref.watch(
      onboardingControllerProvider.select((s) => s.feelings),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    final serif = Theme.of(context).textTheme.headlineMedium!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            Text(
              'How do you feel today?',
              textAlign: TextAlign.center,
              style: serif.copyWith(color: AppColors.entryAccent, fontSize: 26),
            ),
            const SizedBox(height: 4),
            const Text(
              'choose all that apply',
              style: TextStyle(fontSize: 13, color: AppColors.entryHint),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                crossAxisCount: 3,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                childAspectRatio: 0.74,
                children: [
                  for (final feeling in Feeling.values)
                    _FeelingCard(
                      feeling: feeling,
                      selected: feelings.contains(feeling),
                      onTap: () => controller.toggleFeeling(feeling),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: feelings.isEmpty
                          ? [AppColors.entryPlaceholder, AppColors.entryPlaceholder]
                          : [AppColors.entryAccent, AppColors.entryAccentDark],
                    ),
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(29),
                      onTap: feelings.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Center(
                        child: Text(
                          'Done   ✦',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta del grid de sentimientos (estilo aprobado): fondo blanco limpio,
/// la ilustración en un marco interior redondeado y el nombre en serif debajo.
/// Seleccionada: borde rosado más presente + sombra suave (sin cambiar fondo).
class _FeelingCard extends StatelessWidget {
  const _FeelingCard({
    required this.feeling,
    required this.selected,
    required this.onTap,
  });

  final Feeling feeling;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.entryAccent : AppColors.entryBorder,
            width: selected ? 1.6 : 1.1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.entryAccent.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Marco interior de la ilustración (como el maquetado).
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF5E6ED)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(feeling.imageAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              feeling.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: AppTypography.serif,
                fontSize: 12.5,
                height: 1.12,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La frase continua en serif, construida PROGRESIVAMENTE (maquetado): solo se
/// muestran las líneas ya respondidas y la del paso actual, que aparece con un
/// fundido suave. El valor va en bold magenta; si falta, placeholder rosado.
class _Sentence extends StatelessWidget {
  const _Sentence({
    required this.state,
    required this.active,
    this.onLineTap,
    this.showAll = false,
    this.nameEditor,
  });

  final OnboardingState state;
  final _Segment active;

  /// "Tap any word to edit it" (maquetado): tocar una línea vuelve a su paso.
  final ValueChanged<_Segment>? onLineTap;

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
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: AppColors.entryInk,
        );

    TextSpan value(String? text, String placeholder, _Segment segment) {
      final missing = text == null;
      return TextSpan(
        text: missing ? placeholder : text,
        style: serif.copyWith(
          color: missing ? AppColors.entryPlaceholder : AppColors.entryAccent,
          fontWeight: missing ? FontWeight.w400 : FontWeight.w700,
          fontStyle: missing ? FontStyle.italic : FontStyle.normal,
          decoration:
              segment == active ? TextDecoration.underline : TextDecoration.none,
          decorationColor: AppColors.entryAccent.withValues(alpha: 0.45),
          decorationThickness: 2,
        ),
      );
    }

    final name = state.name.trim().isEmpty ? null : state.name.trim();
    final age = state.age?.toString();
    final children = state.childrenCount?.toString();
    final feeling = _joinFeelings(state.feelings);

    Widget line(_Segment segment, Widget child, {bool tappable = true}) {
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
          _Segment.name,
          Column(
            children: [
              Text('My name is', textAlign: TextAlign.center, style: serif),
              nameEditor ??
                  rich([
                    value(name, 'your name', _Segment.name),
                    TextSpan(text: ',', style: serif),
                  ]),
            ],
          ),
          tappable: nameEditor == null,
        ),
        line(
          _Segment.age,
          rich([
            TextSpan(text: 'I am ', style: serif),
            value(age, '··', _Segment.age),
            TextSpan(text: ' years old', style: serif),
          ]),
        ),
        line(
          _Segment.children,
          rich([
            TextSpan(text: 'with ', style: serif),
            value(children, '··', _Segment.children),
            TextSpan(
              text: (state.childrenCount ?? 2) == 1 ? ' child' : ' children',
              style: serif,
            ),
          ]),
        ),
        line(
          _Segment.feeling,
          rich([
            TextSpan(text: 'I feel like ', style: serif),
            value(feeling, 'this', _Segment.feeling),
            TextSpan(text: '.', style: serif),
          ]),
        ),
      ],
    );
  }
}

/// Stepper −/+ del maquetado (edad y nº de peques).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.placeholder,
    required this.min,
    required this.max,
    required this.initial,
    required this.onChanged,
  });

  final int? value;
  final String placeholder;
  final int min;
  final int max;
  final int initial;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    void step(int delta) {
      final next = ((value ?? initial) + delta).clamp(min, max);
      onChanged(next);
    }

    // Botones ± del maquetado: círculos grises rellenos, sin borde.
    Widget button(String symbol, VoidCallback onPressed) => InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onPressed,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1EFF3),
            ),
            child: Text(
              symbol,
              style: const TextStyle(fontSize: 22, color: AppColors.textPrimary),
            ),
          ),
        );

    // Sin tocar aún: el número de partida en rosado tenue; al tocar ±, crimson.
    final untouched = value == null;
    final display = (value ?? initial).toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        button('−', () => step(-1)),
        Container(
          width: 104,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F8),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: untouched ? AppColors.entryBorder : AppColors.entryAccent,
              width: 1.5,
            ),
          ),
          child: Text(
            display,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 24,
                  color: untouched
                      ? AppColors.entryPlaceholder
                      : AppColors.entryAccent,
                ),
          ),
        ),
        button('+', () => step(1)),
      ],
    );
  }
}

/// Control de peques: stepper 0–4+ y, si hay, chips de edades (multi).
class _ChildrenControl extends ConsumerWidget {
  const _ChildrenControl({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final count = state.childrenCount;
    final ages = state.childrenAges;

    void toggleAge(ChildAge age) {
      final next = [...ages];
      if (!next.remove(age)) next.add(age);
      controller.setChildren(count: count ?? 0, ages: next);
    }

    return Column(
      children: [
        // Num-chips del maquetado v2: elegir el número en UN tap.
        const Text(
          'How many kids?',
          style: TextStyle(fontSize: 12, color: AppColors.entryHint),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var n = 0; n <= 5; n++)
              InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => controller.setChildren(
                  count: n,
                  ages: n == 0 ? const [] : ages,
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: count == n
                        ? const Color(0xFFFFF0F4)
                        : const Color(0xFFF8F4FC),
                    border: Border.all(
                      color: count == n
                          ? AppColors.entryAccent
                          : const Color(0xFFE8E0F0),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    n == 5 ? '5+' : '$n',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: count == n
                          ? AppColors.entryAccent
                          : const Color(0xFF5A4F6A),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (count != null && count > 0) ...[
          const SizedBox(height: 14),
          const Text(
            'What ages? (choose all that apply)',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final age in ChildAge.values)
                SelectableChip(
                  label: age.label,
                  selected: ages.contains(age),
                  onTap: () => toggleAge(age),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Pasos 5–7 · frase en primera persona (mezcla v2, aprobada) ───────────────

/// Andamio de los pasos finales: la frase arriba con el valor tejido en
/// carmesí, el control anclado abajo con su microcopy empático, y el enlace
/// de cancelar — misma distribución que los pasos de la frase personal.
class _FirstPersonStep extends StatelessWidget {
  const _FirstPersonStep({
    required this.spans,
    required this.chipsLabel,
    required this.control,
    this.microcopy,
  });

  /// Las líneas de la frase (serif gris con el valor en carmesí).
  final List<InlineSpan> spans;
  final String chipsLabel;
  final Widget control;

  /// Línea validadora bajo el control (tono del Sistema Emocional).
  final String? microcopy;

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: AppColors.entryInk,
        );

    return Column(
      children: [
        const SizedBox(height: 34),
        TweenAnimationBuilder<double>(
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
          child: Text.rich(
            TextSpan(children: spans),
            textAlign: TextAlign.center,
            style: serif,
          ),
        ),
        const Spacer(),
        Text(
          chipsLabel,
          style: const TextStyle(fontSize: 12, color: AppColors.entryHint),
        ),
        const SizedBox(height: 10),
        control,
        if (microcopy != null) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              microcopy!,
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
        ],
        const SizedBox(height: 6),
        const _CancelLink(),
      ],
    );
  }
}

/// Span del valor tejido en la frase: carmesí bold, o placeholder rosado.
TextSpan _wovenValue(BuildContext context, String? text, String placeholder) {
  final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.36,
        color: AppColors.entryInk,
      );
  final missing = text == null;
  return TextSpan(
    text: missing ? placeholder : text,
    style: serif.copyWith(
      color: missing ? AppColors.entryPlaceholder : AppColors.entryAccent,
      fontWeight: missing ? FontWeight.w400 : FontWeight.w700,
      fontStyle: missing ? FontStyle.italic : FontStyle.normal,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.entryAccent.withValues(alpha: 0.4),
      decorationThickness: 1.5,
    ),
  );
}

// ── Paso 5 · Lo que más pesa ──────────────────────────────────────────────────
class _StepMainPain extends ConsumerWidget {
  const _StepMainPain();

  /// Cómo se lee cada elección dentro de la frase.
  static const _sentenceValue = {
    MainPain.work: 'work',
    MainPain.family: 'my family and home',
    MainPain.self: 'myself',
    MainPain.relationships: 'my relationships',
    MainPain.all: 'everything at once',
  };

  /// Microcopy reactivo: valida la elección, nunca aconseja ni exige
  /// (tono del Sistema Emocional; salda el pendiente del incremento 2).
  static const _microcopy = {
    MainPain.work:
        'Work asks a lot. Wanting room for yourself too is not asking too much.',
    MainPain.family:
        'The home never clocks out. What you do there counts, even when no one sees it.',
    MainPain.self:
        'Turning toward yourself is not selfish. It is where everything else starts.',
    MainPain.relationships:
        'Relationships take energy too. Noticing that is already caring for them.',
    MainPain.all:
        'When it is everything at once, no one could carry it lightly. You are not failing.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.mainPain),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: AppColors.entryInk,
        );

    return _FirstPersonStep(
      spans: [
        TextSpan(text: 'Right now,\nthe hardest part is\n', style: serif),
        _wovenValue(context, _sentenceValue[selected], 'this'),
        TextSpan(text: '.', style: serif),
      ],
      chipsLabel: 'What weighs on you most?',
      control: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final pain in MainPain.values)
            SelectableChip(
              label: pain.label,
              selected: selected == pain,
              onTap: () => controller.setMainPain(pain),
            ),
        ],
      ),
      microcopy: selected == null ? null : _microcopy[selected],
    );
  }
}

// ── Paso 6 · Tiempo disponible ────────────────────────────────────────────────
class _StepTime extends ConsumerWidget {
  const _StepTime();

  static const _sentenceValue = {
    TimeSlot.minimal: '5 minutes',
    TimeSlot.short: '10–20 minutes',
    TimeSlot.medium: '30+ minutes',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.dailyTimeSlot),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: AppColors.entryInk,
        );

    return _FirstPersonStep(
      spans: [
        TextSpan(text: 'Each day,\nI have about\n', style: serif),
        _wovenValue(context, _sentenceValue[selected], 'some time'),
        TextSpan(text: '\nfor myself.', style: serif),
      ],
      chipsLabel: 'How much time do you have each day?',
      control: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final slot in TimeSlot.values)
            SelectableChip(
              label: slot.label,
              selected: selected == slot,
              onTap: () => controller.setTimeSlot(slot),
            ),
        ],
      ),
      // Anti-vergüenza: promete poco en el momento exacto de la decisión.
      microcopy:
          'Ten minutes a day is enough to build something that matters. '
          'Aura+ adapts to what you have.',
    );
  }
}

// ── Paso 7 · Momento Aura+ ────────────────────────────────────────────────────
class _StepMoment extends ConsumerWidget {
  const _StepMoment();

  static const _sentenceValue = {
    PreferredMoment.earlyMorning: 'early,\nbefore the noise',
    PreferredMoment.morning: 'mid-morning',
    PreferredMoment.midday: 'at midday',
    PreferredMoment.night: 'at night,\nwhen they sleep',
  };

  /// Chips con subtítulo (maquetado v2).
  static const _subLabel = {
    PreferredMoment.earlyMorning: 'before the noise',
    PreferredMoment.morning: 'once the day has started',
    PreferredMoment.midday: 'a pause in the middle',
    PreferredMoment.night: 'when the kids sleep',
  };

  static const _shortLabel = {
    PreferredMoment.earlyMorning: 'Early morning',
    PreferredMoment.morning: 'Mid-morning',
    PreferredMoment.midday: 'Midday',
    PreferredMoment.night: 'Night',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.preferredMoment),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);
    final serif = Theme.of(context).textTheme.displaySmall!.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          height: 1.36,
          color: AppColors.entryInk,
        );

    return _FirstPersonStep(
      spans: [
        TextSpan(text: 'My Aura+\nmoment is\n', style: serif),
        _wovenValue(context, _sentenceValue[selected], 'yours to choose'),
        TextSpan(text: '.', style: serif),
      ],
      chipsLabel: 'When is your moment?',
      control: Column(
        children: [
          for (final moment in PreferredMoment.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MomentChip(
                title: _shortLabel[moment]!,
                subtitle: _subLabel[moment]!,
                selected: selected == moment,
                onTap: () => controller.setMoment(moment),
              ),
            ),
        ],
      ),
      // La promesa del producto, explícita en el momento de la decisión.
      microcopy: 'One message a day, at this moment. Nothing more.',
    );
  }
}

/// Chip de momento con subtítulo (time-chip del maquetado v2).
class _MomentChip extends StatelessWidget {
  const _MomentChip({
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
          color: selected ? const Color(0xFFFFF0F4) : const Color(0xFFF8F4FC),
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
class _CancelLink extends ConsumerWidget {
  const _CancelLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: ref.read(onboardingControllerProvider.notifier).restart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cancel and start again',
            // Regular, no bold (el TextButton hereda w600 del labelLarge).
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFECEAEE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 13, color: Color(0xFF8B8692)),
          ),
        ],
      ),
    );
  }
}

/// "agotada", "agotada y sola", "agotada, sola y culpable" (para la frase).
String? _joinFeelings(List<Feeling> feelings) {
  if (feelings.isEmpty) return null;
  final labels = [for (final f in feelings) f.label.toLowerCase()];
  if (labels.length == 1) return labels.single;
  return '${labels.sublist(0, labels.length - 1).join(', ')} and ${labels.last}';
}

/// Contrato emocional (SPEC_CONTENIDO_EMOCIONAL_V2 §3.2): estado de éxito del
/// onboarding. Sin metas ni presión — cierra el arco de entrada. La usuaria
/// decide cuándo entrar, con un único botón.
class _EmotionalContract extends StatelessWidget {
  const _EmotionalContract({required this.name, required this.onEnter});

  final String name;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.displaySmall!;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 28),
          child: Column(
            children: [
              const Spacer(),
              const Text('✦',
                  style: TextStyle(fontSize: 30, color: AppColors.entryAccent)),
              const SizedBox(height: 22),
              // Frase-contrato: el nombre en carmesí, el resto en tinta suave.
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: 'Eso es todo lo que necesito, ',
                    style: serif.copyWith(color: AppColors.entryInk, height: 1.35),
                  ),
                  TextSpan(
                    text: name,
                    style: serif.copyWith(
                        color: AppColors.entryAccent, height: 1.35),
                  ),
                  TextSpan(
                    text: '.',
                    style: serif.copyWith(color: AppColors.entryInk, height: 1.35),
                  ),
                ]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text(
                'Aquí no hay metas que cumplir ni nada que demostrar.\n'
                'Empezamos cuando quieras.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.entryMuted,
                ),
              ),
              const Spacer(),
              SoftPrimaryButton(
                label: 'Entrar a mi espacio',
                onPressed: onEnter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
