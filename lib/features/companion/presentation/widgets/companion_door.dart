import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
          // push (no go): al salir del chat el "atrás" vuelve AQUÍ, no a una
          // pantalla fija. Misma regla que las puertas de Care.
          onTap: () => context.push(AppRoutes.companion),
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

    // Mismo card que "Talk with Aura" en la tab Care (icono destello, título,
    // subtítulo, hojas y chevron), pero el subtítulo lleva el mensaje CONTEXTUAL
    // del día duro: la contención sigue, con el lenguaje visual del resto.
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // push (no go): al salir del chat el "atrás" vuelve AQUÍ, no a una
          // pantalla fija. Misma regla que las puertas de Care.
          onTap: () => context.push(AppRoutes.companion),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // Carmesí OSCURO: mismo tratamiento que la puerta de Aura en Care.
              // Carmesí oscuro PÁLIDO: a plena intensidad el card parecía
              // seleccionado en vez de uno más. El título y el icono sí van al
              // tono fuerte.
              border: Border.all(color: const Color(0xFFE4CBD4)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/care/card3.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                    opacity: const AlwaysStoppedAnimation(0.22),
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.roseTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            size: 20, color: AppColors.primaryDark),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Talk with Aura',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Days like this weigh more when nobody hears '
                              'them. If you want, tell me.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 20, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
