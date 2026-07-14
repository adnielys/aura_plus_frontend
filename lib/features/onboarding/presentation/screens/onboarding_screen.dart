import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/selectable_chip.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/onboarding_controller.dart';

/// Flujo de onboarding: 6 pasos en una sola pantalla (nombre → sentimiento →
/// hijos → dolor → tiempo → momento). Navegación hacia adelante controlada por
/// el CTA; el estado vive en el [OnboardingController], así que avanzar y volver
/// conserva las respuestas. Al completar, el router redirige a Home.
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

    return Scaffold(
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
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                  child: _StepContent(step: state.stepIndex),
                ),
              ),
            ),
            _StepDots(active: state.stepIndex),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              child: SoftPrimaryButton(
                label: state.isLastStep ? 'Empezar' : 'Continuar',
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
              color: i <= active ? AppColors.primary : const Color(0xFFE8E0F0),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
      ],
    );
  }
}

/// Selecciona el widget del paso actual.
class _StepContent extends StatelessWidget {
  const _StepContent({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      0 => const _StepName(),
      1 => const _StepFeeling(),
      2 => const _StepChildren(),
      3 => const _StepMainPain(),
      4 => const _StepTime(),
      _ => const _StepMoment(),
    };
  }
}

/// Layout común de un paso: una "frase" en serif y debajo el control.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

// ── Paso 1 · Nombre ──────────────────────────────────────────────────────────
class _StepName extends ConsumerStatefulWidget {
  const _StepName();

  @override
  ConsumerState<_StepName> createState() => _StepNameState();
}

class _StepNameState extends ConsumerState<_StepName> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(onboardingControllerProvider).name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '¿Cómo quieres que te llame?',
      child: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 50,
        onChanged: ref.read(onboardingControllerProvider.notifier).setName,
        decoration: InputDecoration(
          hintText: 'Tu nombre',
          counterText: '',
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFFD8D0E0), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: Color(0xFFD8D0E0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Paso 2 · Cómo se siente ───────────────────────────────────────────────────
class _StepFeeling extends ConsumerWidget {
  const _StepFeeling();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.initialFeeling),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);

    return _StepScaffold(
      title: '¿Cómo te sientes hoy?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final feeling in EmotionalState.values)
            SelectableChip(
              label: feeling.label,
              selected: selected == feeling,
              onTap: () => controller.setFeeling(feeling),
            ),
        ],
      ),
    );
  }
}

// ── Paso 3 · Hijos ────────────────────────────────────────────────────────────
class _StepChildren extends ConsumerWidget {
  const _StepChildren();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      onboardingControllerProvider.select((s) => s.childrenCount),
    );
    final ages = ref.watch(
      onboardingControllerProvider.select((s) => s.childrenAges),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);

    void setCount(int value) => controller.setChildren(
          count: value,
          ages: value == 0 ? const [] : ages,
        );

    void toggleAge(ChildAge age) {
      final next = [...ages];
      if (next.contains(age)) {
        next.remove(age);
      } else {
        next.add(age);
      }
      controller.setChildren(count: count ?? 0, ages: next);
    }

    return _StepScaffold(
      title: '¿Tienes peques en casa?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var n = 0; n <= 4; n++)
                SelectableChip(
                  label: n == 4 ? '4+' : '$n',
                  selected: count == n,
                  onTap: () => setCount(n),
                ),
            ],
          ),
          if (count != null && count > 0) ...[
            const SizedBox(height: 24),
            const Text(
              '¿De qué edades? (puedes elegir varias)',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
      ),
    );
  }
}

// ── Paso 4 · Lo que más pesa ──────────────────────────────────────────────────
class _StepMainPain extends ConsumerWidget {
  const _StepMainPain();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.mainPain),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);

    return _StepScaffold(
      title: '¿Qué es lo que más pesa ahora?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final pain in MainPain.values)
            SelectableChip(
              label: pain.label,
              selected: selected == pain,
              onTap: () => controller.setMainPain(pain),
            ),
        ],
      ),
    );
  }
}

// ── Paso 5 · Tiempo disponible ────────────────────────────────────────────────
class _StepTime extends ConsumerWidget {
  const _StepTime();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.dailyTimeSlot),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);

    return _StepScaffold(
      title: '¿Cuánto tiempo tienes al día?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final slot in TimeSlot.values)
            SelectableChip(
              label: slot.label,
              selected: selected == slot,
              onTap: () => controller.setTimeSlot(slot),
            ),
        ],
      ),
    );
  }
}

// ── Paso 6 · Momento Aura+ ────────────────────────────────────────────────────
class _StepMoment extends ConsumerWidget {
  const _StepMoment();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      onboardingControllerProvider.select((s) => s.preferredMoment),
    );
    final controller = ref.read(onboardingControllerProvider.notifier);

    return _StepScaffold(
      title: '¿Cuál es tu momento Aura+?',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final moment in PreferredMoment.values)
            SelectableChip(
              label: moment.label,
              selected: selected == moment,
              onTap: () => controller.setMoment(moment),
            ),
        ],
      ),
    );
  }
}
