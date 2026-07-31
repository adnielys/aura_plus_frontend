import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../providers/companion_provider.dart';

/// La PUERTA al acompañante (mockup aprobado jul 2026): una frase al pie del
/// Home, no un botón que llama.
///
/// Reglas duras del diseño, y son deliberadas:
///   · sin badge, sin contador de no leídos, sin "Aura te escribió";
///   · Aura JAMÁS inicia la conversación — esta puerta solo se abre desde
///     aquí;
///   · si el acompañante está apagado en el servidor, no aparece nada (nunca
///     una promesa vacía).
/// Un chat es una superficie que pide ser alimentada; con un puntito rojo se
/// convertiría en una tarea pendiente más, y Aura+ promete un mensaje al día.
class CompanionDoor extends ConsumerWidget {
  const CompanionDoor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(companionAvailableProvider).valueOrNull ?? false;
    if (!available) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 18),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(AppRoutes.companion),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Text(
                  'Do you want to tell me something?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "I'm here, no rush",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFA79FAD)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Invitación CONTEXTUAL: solo tras un check-in "al límite" o "cansada" — el
/// momento en que la contención vale. Nunca en un día cualquiera.
class CompanionInvite extends ConsumerWidget {
  const CompanionInvite({super.key, required this.state});

  final EmotionalState state;

  static bool fitsToday(EmotionalState state) =>
      state == EmotionalState.hard || state == EmotionalState.exhausted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!fitsToday(state)) return const SizedBox.shrink();
    final available = ref.watch(companionAvailableProvider).valueOrNull ?? false;
    if (!available) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0C3D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Days like this weigh more when nobody hears them. '
            'If you want, tell me.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.55,
              color: Color(0xFF72243E),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.go(AppRoutes.companion),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2A9BF)),
              ),
              child: const Center(
                child: Text(
                  'Talk with Aura',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
