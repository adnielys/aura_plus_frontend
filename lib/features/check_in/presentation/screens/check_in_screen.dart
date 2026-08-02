import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/soft_primary_button.dart';
import '../providers/daily_flow_controller.dart';
import '../widgets/energy_visuals.dart';

/// Check-in de energía (maquetado `aura_preview` · pantalla "checkin"):
/// 5 tarjetas con ilustración, nombre y una promesa pequeña. El check-in mismo
/// ya es el logro; ninguna respuesta es incorrecta.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  EmotionalState? _selected;
  bool _submitting = false;

  Future<void> _continue() async {
    final selected = _selected;
    if (selected == null || _submitting) return;
    setState(() => _submitting = true);
    final ok =
        await ref.read(dailyFlowProvider.notifier).submit(selected);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      context.go(AppRoutes.checkInResult);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text("We couldn't save it. Try again in a moment."),
        ));
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 19) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.headlineMedium!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                children: [
                  // Cabecera centrada (maquetado): saludo tenue, pregunta serif
                  // con "energy" en carmesí itálica, y la promesa de Aura.
                  Text(
                    _greeting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'How much ', style: serif),
                      TextSpan(
                        text: 'energy',
                        style: serif.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(text: ' today?', style: serif),
                    ]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Aura shapes your day around it',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  // Hero: cambia a la ilustración del estado elegido a medida
                  // que ella toca cada tarjeta (recoHeroAsset). Antes de elegir,
                  // la imagen genérica "energía personal" que invita.
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Image.asset(
                        _selected?.recoHeroAsset ??
                            'assets/images/energy/energia_personal.png',
                        key: ValueKey(_selected),
                        height: 220,
                        fit: BoxFit.contain,
                        // Decorativa: el estado se anuncia por las tarjetas.
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final state in checkInOrder) ...[
                    _StateCard(
                      state: state,
                      selected: _selected == state,
                      onTap: () => setState(() => _selected = state),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
              child: SoftPrimaryButton(
                label: 'Continue',
                onPressed: _selected == null ? null : _continue,
                isLoading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de estado del maquetado: ilustración redonda + nombre + promesa +
/// radio. Seleccionada: fondo rosa suave y borde magenta.
class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.state,
    required this.selected,
    required this.onTap,
  });

  final EmotionalState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Grupo de radios accesible: el lector anuncia la etiqueta y si está
    // elegida (antes no había forma de saber cuál estaba seleccionada).
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: '${state.checkInLabel}. ${state.checkInHint}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ExcludeSemantics(
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.roseTint : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Image.asset(
                state.imageAsset,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.checkInLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.checkInHint,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? AppColors.primary : const Color(0xFFD8D0E0),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(CupertinoIcons.checkmark, size: 13, color: Colors.white)
                  : null,
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}
