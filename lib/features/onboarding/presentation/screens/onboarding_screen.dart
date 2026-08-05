import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/selectable_chip.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';
import '../widgets/pain_reflection.dart';

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
    final editing = ref.watch(_editingSegmentProvider);

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
            // Sin flecha de volver: no hace falta retroceder de paso porque
            // cualquier dato se corrige tocando su palabra en la frase, y eso
            // abre su sheet/modal SIN mover el paso — así la frase nunca
            // pierde líneas.
            const SizedBox(height: 28),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  key: ValueKey(state.stepIndex),
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                  // Scrollable SIN perder los Spacer: los pasos eran una Column
                  // rígida, así que con varios sentimientos elegidos —o en una
                  // pantalla pequeña— el contenido desbordaba. El IntrinsicHeight
                  // mantiene el anclaje abajo cuando sobra sitio y deja hacer
                  // scroll cuando falta.
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: _StepContent(step: state.stepIndex),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _StepDots(active: state.stepIndex),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              // Reeditando un dato de la frase, el botón CIERRA la edición y
              // deja donde estabas; no avanza. Antes tocar el nombre y darle a
              // "Continue" te empujaba al paso siguiente.
              child: editing != null
                  ? SoftPrimaryButton(
                      label: 'Done',
                      onPressed: () =>
                          ref.read(_editingSegmentProvider.notifier).state =
                              null,
                    )
                  : SoftPrimaryButton(
                      label:
                          state.isLastStep ? 'Start with Aura+' : 'Continue',
                      onPressed: state.canContinue
                          ? (state.isLastStep
                              ? controller.submit
                              : controller.next)
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
/// Puntos de progreso: el paso activo se alarga en magenta (como el maquetado).
class _StepDots extends StatelessWidget {
  const _StepDots({required this.active});

  final int active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < kOnboardingSteps; i++)
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
        // Cuánto queda, en palabras: con 7 pasos unos puntos de 6px no bastan
        // — y el resumen del paso 4 se leía como un final que no era.
        Text(
          'Step ${active + 1} of $kOnboardingSteps',
          style: const TextStyle(fontSize: 11, color: AppColors.entryHint),
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
      // Dos párrafos acumulativos con el mismo cromo: el personal (nombre,
      // edad, peques, sentimiento) y el del día (lo que pesa, tiempo, momento).
      0 || 1 || 2 || 3 => _StepSentence(activeSegment: _Segment.values[step]),
      _ => _ClosingStep(active: _ClosingSegment.values[step - 4]),
    };
  }
}

// ── Pasos 1–4 · Frase continua progresiva (maquetado) ────────────────────────

/// Fuerza la mayúscula inicial del nombre. Solo toca el primer carácter, así
/// que la longitud no cambia y el cursor NO salta mientras se escribe.
class _CapitalizeFirst extends TextInputFormatter {
  const _CapitalizeFirst();

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

/// Segmentos de la frase; su orden es el de los pasos 0–3.
enum _Segment { name, age, children, feeling }

/// Dato que se está reeditando desde la frase (null = ninguno).
///
/// Vive FUERA del State porque el botón primario está en la pantalla y tiene
/// que saberlo: mientras se edita, ese botón cierra la edición y NO avanza de
/// paso. Si no, tocar el nombre y confirmar te empujaba al paso siguiente en
/// vez de devolverte donde estabas.
final _editingSegmentProvider = StateProvider<_Segment?>((ref) => null);

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
      _Segment.age => _openAgeSheet,
      _Segment.children => _openChildrenSheet,
      _Segment.feeling => _openFeelingsModal,
      _Segment.name => null, // se escribe en la propia línea
    };
    if (opener != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) opener();
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
              inputFormatters: const [_CapitalizeFirst()],
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

    // Volver a un dato ya respondido: cada uno abre SU sheet o su modal, y
    // ninguno mueve el paso — así la frase de detrás nunca pierde líneas.
    // (El nombre hacía goToStep(0) y borraba todo lo posterior.)
    Widget tappable(_Segment target, Widget child) => GestureDetector(
          onTap: () => switch (target) {
            // El nombre NO abre sheet: su línea se convierte en el campo y
            // sale el teclado. Se escribe en la frase, que es la gracia.
            _Segment.name => _startEditingName(),
            _Segment.age => _openAgeSheet(),
            _Segment.children => _openChildrenSheet(),
            _Segment.feeling => _openFeelingsModal(),
          },
          behavior: HitTestBehavior.opaque,
          child: child,
        );

    // El nombre ocupa SU PROPIA línea bajo "My name is" (saltos del maquetado).
    // Al tocarlo, esa línea SE CONVIERTE en el campo: solo teclado, sin sheet.
    if (segment == _Segment.name) {
      final editing = ref.watch(_editingSegmentProvider) == _Segment.name;
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
      return editing ? line : tappable(_Segment.name, line);
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
      _Segment.name => Column(
          children: [
            Text('My name is', textAlign: TextAlign.center, style: serif),
            _inlineNameRow(serif),
          ],
        ),
      // Tocar la línea reabre el sheet: es la única forma de volver a él una
      // vez cerrado, y el subrayado del valor ya invita a tocarlo.
      _Segment.age => GestureDetector(
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
      _Segment.children => GestureDetector(
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
      _Segment.feeling => GestureDetector(
          onTap: _openFeelingsModal,
          behavior: HitTestBehavior.opaque,
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'I feel ', style: serif),
              value(
                state.feelings.isEmpty ? null : _joinFeelings(state.feelings),
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
    ref.read(_editingSegmentProvider.notifier).state = _Segment.name;
  }

  Future<void> _openChildrenSheet() => _openSheet(const _ChildrenSheet());

  /// Bottom sheet de la edad.
  Future<void> _openAgeSheet() => _openSheet(const _AgeSheet());

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
    final editing = ref.watch(_editingSegmentProvider);

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
              height: 215,
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
              case _Segment.name:
                _startEditingName();
              case _Segment.age:
                _openAgeSheet();
              case _Segment.children:
                _openChildrenSheet();
              case _Segment.feeling:
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
                  ref.read(_editingSegmentProvider.notifier).state = null,
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
            // Cruz de cerrar: el modal se abre solo al llegar al paso, así que
            // la salida tiene que estar a la vista. Antes solo se salía
            // eligiendo un sentimiento.
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(CupertinoIcons.xmark,
                    size: 20, color: AppColors.entryInk),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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
              child: SoftPrimaryButton(
                label: 'Done',
                onPressed:
                    feelings.isEmpty ? null : () => Navigator.of(context).pop(),
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
            // Ilustración sin marco interior: solo el borde externo de la card.
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
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
          fontSize: 33,
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
          decorationColor: AppColors.entryAccent.withValues(alpha: 0.4),
          decorationThickness: 1.5,
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
            TextSpan(text: 'I feel ', style: serif),
            value(feeling, 'like this', _Segment.feeling),
            TextSpan(text: '.', style: serif),
          ]),
        ),
      ],
    );
  }
}

/// Andamio común de los bottom sheets del onboarding: asa, contenido y el
/// botón de cerrar. Los datos se guardan al tocar, así que "Done" solo cierra.
class _OnboardingSheet extends ConsumerWidget {
  const _OnboardingSheet({required this.children, required this.note});

  final List<Widget> children;

  /// Por qué se pregunta el dato. Va DENTRO del sheet, junto al "Skip": es
  /// donde se decide, no en la pantalla de detrás.
  final String note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Padding(
        // viewInsets: sin esto el teclado (el sheet del nombre lo abre con
        // autofocus) tapaba el contenido entero — se veía solo el fondo.
        padding: EdgeInsets.fromLTRB(
          24,
          10,
          24,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Asa: dice "esto se arrastra y se cierra".
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E0F0),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 18),
            ...children,
            const SizedBox(height: 18),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.serif,
                fontStyle: FontStyle.italic,
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.entryHint,
              ),
            ),
            TextButton(
              // Saltar cierra el sheet Y avanza: el dato es opcional de verdad.
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(onboardingControllerProvider.notifier).next();
              },
              child: const Text(
                'Skip for now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.entryAccent,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SoftPrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de la edad: el mismo stepper, con su propia salida.
class _AgeSheet extends ConsumerWidget {
  const _AgeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = ref.watch(onboardingControllerProvider.select((s) => s.age));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return _OnboardingSheet(
      note: 'Only so Aura can pace your days. You can skip this — it changes '
          'nothing about what she offers you.',
      children: [
        const Text(
          'How old are you?',
          style: TextStyle(fontSize: 12, color: AppColors.entryHint),
        ),
        const SizedBox(height: 14),
        _Stepper(
          value: age,
          placeholder: "I'd rather not say",
          min: 16,
          max: 99,
          initial: 25, // punto de partida del maquetado
          onChanged: controller.setAge,
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
class _ChildrenSheet extends ConsumerWidget {
  const _ChildrenSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final count = state.childrenCount;
    final ages = state.childrenAges;

    void toggleAge(ChildAge age) {
      final next = [...ages];
      if (!next.remove(age)) next.add(age);
      controller.setChildren(count: count ?? 0, ages: next);
    }

    return _OnboardingSheet(
      note: 'It helps Aura suggest gestures that fit your home. Skipping is '
          'just as valid.',
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
                        ? AppColors.roseTint
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
/// Los tres datos del cierre; su orden es el de los pasos 4–6.
enum _ClosingSegment { pain, time, moment }

/// Bloque de cierre (pasos 5–7): SEGUNDO párrafo acumulativo, con el mismo
/// cromo que el personal — rótulo, ilustración y la frase creciendo línea a
/// línea. Antes cada uno era una frase suelta sin cabecera ni imagen, y el
/// flujo se partía en dos: se sentía como otro formulario.
class _ClosingStep extends ConsumerStatefulWidget {
  const _ClosingStep({required this.active});

  final _ClosingSegment active;

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
      if (mounted) _openSheet(widget.active);
    });
  }

  Future<void> _openSheet(_ClosingSegment segment) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final (title, control, microcopy) = switch (segment) {
      _ClosingSegment.pain => (
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
            return _Microcopy(chosen == null ? null : painReflections[chosen]);
          }),
        ),
      _ClosingSegment.time => (
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
            return _Microcopy(chosen == null
                ? timeReflectionDefault
                : timeReflections[chosen]);
          }),
        ),
      _ClosingSegment.moment => (
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
                    child: _MomentChip(
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
            return _Microcopy(chosen == null
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
          _ChoiceSheet(title: title, control: control, microcopy: microcopy),
    );
  }

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
    Widget line(_ClosingSegment segment, List<InlineSpan> spans) {
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
            'assets/images/onboarding/feelings-header.png',
            height: 215,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
        line(_ClosingSegment.pain, [
          TextSpan(text: 'Right now, the hardest part is ', style: serif),
          value(_painValue[state.mainPain], 'this'),
          TextSpan(text: '.', style: serif),
        ]),
        line(_ClosingSegment.time, [
          TextSpan(text: 'Each day, I have about ', style: serif),
          value(_timeValue[state.dailyTimeSlot], 'some time'),
          TextSpan(text: ' for myself.', style: serif),
        ]),
        line(_ClosingSegment.moment, [
          TextSpan(text: 'My Aura+ moment is ', style: serif),
          value(_momentValue[state.preferredMoment], 'yours to choose'),
          TextSpan(text: '.', style: serif),
        ]),
        const Spacer(),
        const _CancelLink(),
      ],
    );
  }
}

/// Cómo se lee cada elección dentro del párrafo de cierre.
const _painValue = {
  MainPain.work: 'work',
  MainPain.family: 'my family and home',
  MainPain.self: 'myself',
  MainPain.relationships: 'my relationships',
  MainPain.all: 'everything at once',
};

const _timeValue = {
  TimeSlot.minimal: '5 minutes',
  TimeSlot.short: '10–20 minutes',
  TimeSlot.medium: '30+ minutes',
};

const _momentValue = {
  PreferredMoment.earlyMorning: 'early, before the noise',
  PreferredMoment.morning: 'mid-morning',
  PreferredMoment.midday: 'at midday',
  PreferredMoment.night: 'at night, when they sleep',
};

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

/// Sheet de los pasos finales: título, chips y el reflejo empático debajo.
/// No lleva "Skip" — estos tres SÍ son obligatorios para cerrar el onboarding.
class _ChoiceSheet extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.control,
    this.microcopy,
  });

  final String title;
  final Widget control;
  final Widget? microcopy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E0F0),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.entryHint),
            ),
            const SizedBox(height: 14),
            control,
            if (microcopy != null) ...[
              const SizedBox(height: 14),
              microcopy!,
            ],
            const SizedBox(height: 22),
            SoftPrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reflejo empático reactivo: cambia con la selección, con fade suave — Aura
/// responde, no interrumpe (SPEC V2 §3.1).
class _Microcopy extends StatelessWidget {
  const _Microcopy(this.text);

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
class _CancelLink extends ConsumerWidget {
  const _CancelLink();

  /// Borra TODO lo respondido, así que pregunta. Antes bastaba un toque —y el
  /// enlace vive justo encima del botón primario, donde va el pulgar—, así que
  /// un roce en el último paso tiraba siete respuestas sin decir nada.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start again?'),
        content: const Text(
          "Everything you've told me so far will be cleared — your name, how "
          'you feel, all of it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep what I wrote'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start again',
                style: TextStyle(color: AppColors.entryAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
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
        child: Column(
          children: [
            // El cofre CAE hasta casi tocar el texto: clavado arriba dejaba un
            // vacío grande entre la ilustración y "That's all I need". Los dos
            // Expanded (este y el de abajo) reparten el hueco por igual, así
            // que el texto y el botón se quedan donde estaban.
            //
            // Mantiene el tope de altura: sin él, en pantallas estrechas y
            // altas el contain crecía a lo alto y apretaba el texto.
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.34,
                  ),
                  child: Image.asset(
                    'assets/images/onboarding/chest.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 14, 30, 0),
                child: Column(
                  children: [
                    SizedBox(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✦',
                                style: TextStyle(
                                    fontSize: 30,
                                    color: AppColors.entryAccent)),
                            const SizedBox(height: 16),
                            // Frase-contrato: nombre en carmesí, resto en tinta.
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: "That's all I need, ",
                                  style: serif.copyWith(
                                      color: AppColors.entryInk, height: 1.35),
                                ),
                                TextSpan(
                                  text: name,
                                  style: serif.copyWith(
                                      color: AppColors.entryAccent,
                                      height: 1.35),
                                ),
                                TextSpan(
                                  text: '.',
                                  style: serif.copyWith(
                                      color: AppColors.entryInk, height: 1.35),
                                ),
                              ]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Sin salto forzado: con el \n la primera frase
                            // desbordaba y dejaba "prove." sola en su línea.
                            // Que fluya reparte líneas parejas y quita el hueco
                            // entre una frase y otra.
                            const Text(
                              'There are no goals to meet here, nothing to '
                              "prove. We begin whenever you're ready.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.45,
                                color: AppColors.entryMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
            ),
            // Segundo hueco flexible: reparte el aire con el de arriba, de modo
            // que el texto conserva su sitio y el botón sigue anclado abajo.
            const Expanded(child: SizedBox.shrink()),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
              child: SoftPrimaryButton(
                label: 'Enter my space',
                onPressed: onEnter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
