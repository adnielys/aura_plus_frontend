import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
                  Text(
                    _greeting.toUpperCase(),
                    // Eyebrow del maquetado: GFS Didot, en el magenta de la app.
                    style: AppTypography.eyebrow
                        .copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'How much ', style: serif),
                      TextSpan(
                        text: 'energy',
                        style: serif.copyWith(color: AppColors.primary),
                      ),
                      TextSpan(text: ' is there today?', style: serif),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Aura shapes your day around it',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
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
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0F4) : AppColors.surface,
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
                    state.label,
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
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
