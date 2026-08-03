import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../companion/presentation/providers/companion_provider.dart';
import '../providers/care_providers.dart';

/// Tab "Care": cuidado humano (Carril B). Hero ilustrado a fondo completo que
/// se difumina a blanco, dos puertas — apoyo de UNA persona y el círculo — y
/// una nota de privacidad. Discreto, opt-in, sin badges (GUARD_CARE_09).
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  // Borde suave de cada puerta y maroon profundo de la nota de privacidad.
  static const _tealBorder = Color(0xFFCDE6E4);
  static const _roseBorder = Color(0xFFF3D5DF);

  @override
  void initState() {
    super.initState();
    // Polling suave (mismo patrón que el resto de tabs): refresca al entrar.
    Future.microtask(() {
      if (mounted) {
        ref.invalidate(careCurrentReferralProvider);
        // Re-chequea si el acompañante sigue disponible: si se apaga en el
        // servidor, su puerta desaparece sin dejar una promesa vacía.
        ref.invalidate(companionAvailableProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _hero(context),
          _content(context),
        ],
      ),
    );
  }

  // ── Hero: ilustración a fondo completo, difuminándose a blanco, con el
  //    titular carmesí sobreimpreso a la izquierda ─────────────────────────────
  Widget _hero(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final title = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 34,
          height: 1.08,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        );

    return SizedBox(
      height: h * 0.48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/care/hero.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.0, 0.2),
          ),
          // Base difuminada a blanco: se funde con el contenido, sin costura.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: h * 0.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  // Blanco transparente (no Colors.transparent = negro): sin
                  // banda gris al difuminar.
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARE',
                      style: TextStyle(
                        fontFamily: AppTypography.sans,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 12),
                  FractionallySizedBox(
                    widthFactor: 0.72,
                    alignment: Alignment.centerLeft,
                    // Titular a dos tonos (como "Hi, yuki" en Profile): la
                    // primera línea en gris y la segunda en carmesí, para que
                    // el énfasis caiga al final.
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: 'You don’t have\n',
                          style: title.copyWith(color: AppColors.textPrimary),
                        ),
                        const TextSpan(text: 'to walk alone'),
                      ]),
                      style: title,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FractionallySizedBox(
                    widthFactor: 0.56,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'People who can be there — only if and when you '
                      'want. Nothing is shared without your say.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contenido: pregunta + puertas + privacidad ──────────────────────────────
  Widget _content(BuildContext context) {
    // La puerta a Aura solo aparece si el acompañante está encendido en el
    // servidor (misma regla que la puerta del Home: sin promesas vacías).
    final companionOn =
        ref.watch(companionAvailableProvider).valueOrNull ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How would you like support?',
            style: TextStyle(
              fontFamily: AppTypography.sans,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Aura primero: el apoyo inmediato: desde aquí escala a personas.
          if (companionOn) ...[
            _CareCard(
              // Carmesí OSCURO (el aura profundo): distingue la puerta de Aura
              // del resto de puertas, en borde, título e icono.
              accent: AppColors.primaryDark,
              border: AppColors.primaryDark,
              iconTint: AppColors.roseTint,
              leafAsset: 'assets/images/care/card3.png',
              icon: Icons.auto_awesome,
              title: 'Talk with Aura',
              subtitle: 'A quiet space to say it out loud',
              // push (no go): "atrás" vuelve al tab Care, no sale ni va a Profile.
              onTap: () => context.push(AppRoutes.companion),
            ),
            const SizedBox(height: 14),
          ],
          _CareCard(
            accent: AppColors.careAccent,
            border: _tealBorder,
            iconTint: AppColors.careSurface,
            leafAsset: 'assets/images/care/card1.png',
            icon: Icons.volunteer_activism_outlined,
            title: 'Support from one person',
            subtitle: 'People who can walk with you',
            // push (no go): "atrás" vuelve al tab Care, no sale ni va a Profile.
            onTap: () => context.push(AppRoutes.care),
          ),
          const SizedBox(height: 14),
          _CareCard(
            accent: AppColors.primary,
            border: _roseBorder,
            iconTint: AppColors.roseTint,
            leafAsset: 'assets/images/care/card2.png',
            icon: Icons.diversity_3,
            title: 'My circle',
            subtitle: 'Share your light — only if you want',
            onTap: () => context.push(AppRoutes.supportCircle),
          ),
          const SizedBox(height: 20),
          const _PrivacyNote(),
        ],
      ),
    );
  }
}

/// Puerta del care: card blanca con las hojas de fondo, icono e info a la
/// izquierda, título en el color de acento.
class _CareCard extends StatelessWidget {
  const _CareCard({
    required this.accent,
    required this.border,
    required this.iconTint,
    required this.leafAsset,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color accent;
  final Color border;
  final Color iconTint;
  final String leafAsset;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Stack(
            children: [
              // Hojas al ~20% detrás del texto, extendidas por el card (como el
              // diseño de Figma). El texto va encima y sigue legible.
              Positioned.fill(
                child: Image.asset(
                  leafAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topRight,
                  opacity: const AlwaysStoppedAnimation(0.22),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              // Mismas medidas que los cards de Profile (_Row): padding 12,
              // cápsula 40, gap 12, título 14 / subtítulo 12.
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Icono en cápsula redondeada con tinte del área.
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mismo chevron iOS que Profile.
                    const Icon(CupertinoIcons.chevron_right,
                        size: 20, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nota de privacidad con el estilo del mensaje de Aura: fondo oscuro con
/// resplandor y texto serif itálica. Conserva el candado (en vez del punto).
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        // Mismo degradado con resplandor que el aura-message del maquetado.
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0820), Color(0xFF4A0828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.roseTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  const TextSpan(children: [
                    TextSpan(text: 'Your '),
                    TextSpan(
                        text: 'privacy',
                        style: TextStyle(color: AppColors.secondary)),
                    TextSpan(text: ' is our priority'),
                  ]),
                  style: const TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'You’re in control of what you share',
                  style: TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
