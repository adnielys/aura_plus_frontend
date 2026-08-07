import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/selectable_chip.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';

/// Bottom sheets del onboarding (edad, peques, y el de los pasos del día).
/// Salieron de onboarding_screen.dart sin tocarles el comportamiento.

/// Andamio común de los bottom sheets del onboarding: asa, contenido y el
/// botón de cerrar. Los datos se guardan al tocar, así que "Done" solo cierra.
class OnboardingSheet extends ConsumerWidget {
  const OnboardingSheet({
    super.key,
    required this.children,
    required this.note,
  });

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
class AgeSheet extends ConsumerWidget {
  const AgeSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final age = ref.watch(onboardingControllerProvider.select((s) => s.age));
    final controller = ref.read(onboardingControllerProvider.notifier);

    return OnboardingSheet(
      note: 'Only so Aura can pace your days. You can skip this — it changes '
          'nothing about what she offers you.',
      children: [
        const Text(
          'How old are you?',
          style: TextStyle(fontSize: 12, color: AppColors.entryHint),
        ),
        const SizedBox(height: 14),
        NumberStepper(
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

/// Stepper −/+ del maquetado, con el número TAMBIÉN tecleable: llegar a 42
/// desde 25 son 17 toques, y eso es carga mental, no acompañamiento.
class NumberStepper extends StatefulWidget {
  const NumberStepper({
    super.key,
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
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value?.toString() ?? '');

  @override
  void didUpdateWidget(covariant NumberStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Los ± cambian el valor desde fuera; el campo los sigue. La comparación
    // con el texto actual evita pisarle el cursor mientras teclea.
    final incoming = widget.value?.toString() ?? '';
    if (widget.value != oldWidget.value && incoming != _controller.text) {
      _controller.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mientras teclea solo se confirma lo que YA es una respuesta válida: con
  /// "1" a medio escribir un 18 no se puede saltar a 16 y quitarle el dígito
  /// de las manos.
  void _onTyped(String text) {
    final typed = int.tryParse(text);
    if (typed == null) return;
    if (typed < widget.min || typed > widget.max) return;
    if (typed != widget.value) widget.onChanged(typed);
  }

  /// Al soltar el campo se ordena lo tecleado: fuera de rango se acerca al
  /// borde (un ajuste, nunca un error) y vacío vuelve al último valor.
  void _commit() {
    final typed = int.tryParse(_controller.text);
    if (typed == null) {
      _controller.text = widget.value?.toString() ?? '';
      return;
    }
    final clamped = typed.clamp(widget.min, widget.max);
    if (clamped.toString() != _controller.text) {
      _controller.text = clamped.toString();
    }
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    void step(int delta) {
      final next =
          ((widget.value ?? widget.initial) + delta).clamp(widget.min, widget.max);
      widget.onChanged(next);
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

    // Sin tocar aún: el número de partida en rosado tenue (va de hint, así el
    // campo arranca vacío y el primer dígito no pelea con nada); al tocar ±
    // o teclear, crimson.
    final untouched = widget.value == null;
    final number =
        Theme.of(context).textTheme.headlineMedium!.copyWith(fontSize: 24);

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
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textAlign: TextAlign.center,
            cursorColor: AppColors.entryAccent,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(widget.max.toString().length),
            ],
            style: number.copyWith(color: AppColors.entryAccent),
            // isCollapsed + sin borde: el TextField no aporta geometría, la
            // pastilla sigue siendo la del maquetado.
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: widget.initial.toString(),
              hintStyle: number.copyWith(color: AppColors.entryPlaceholder),
            ),
            onChanged: _onTyped,
            onSubmitted: (_) {
              _commit();
              FocusScope.of(context).unfocus();
            },
            // Tocar fuera (los ±, "Skip", "Done") llega ANTES que su pulsación:
            // por eso lo tecleado se confirma aunque salga sin darle a "done".
            onTapOutside: (_) => _commit(),
          ),
        ),
        button('+', () => step(1)),
      ],
    );
  }
}

/// Control de peques: stepper 0–4+ y, si hay, chips de edades (multi).
class ChildrenSheet extends ConsumerWidget {
  const ChildrenSheet({super.key});

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

    return OnboardingSheet(
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

/// Sheet de los pasos finales: título, chips y el reflejo empático debajo.
/// No lleva "Skip" — estos tres SÍ son obligatorios para cerrar el onboarding.
class ChoiceSheet extends StatelessWidget {
  const ChoiceSheet({
    super.key,
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
