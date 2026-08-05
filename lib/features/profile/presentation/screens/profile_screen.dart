import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../care/presentation/providers/care_providers.dart';
import '../../../constellation/presentation/providers/constellation_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../../../../shared/widgets/aura_dialog.dart';
import '../../../../shared/widgets/section_hero.dart';
import '../providers/profile_provider.dart';

/// Perfil (maquetado · tab "perfil"): cabecera con degradado carmesí,
/// SETTINGS y PLAN con iconos carmesí en cápsula rosa.
/// Adaptación de filosofía: el maquetado decía "days of continuous presence"
/// (una racha) — aquí se muestra la presencia ACUMULADA del cielo, que nunca
/// se rompe ni castiga el silencio.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Polling suave de care (GUARD_CARE_09: jamás push): al entrar al perfil
    // se reconsulta el puente — así el "aceptó ✦" aparece aquí, y solo aquí.
    Future.microtask(() {
      if (mounted) ref.invalidate(careCurrentReferralProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final constellation = ref.watch(currentConstellationProvider);
    final notification = ref.watch(notificationSettingsProvider);
    final serif = Theme.of(context).textTheme.headlineMedium!;
    final stars = constellation.valueOrNull?.starsEarned;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero botánico del patrón CARE: acuarela clara difuminándose a
          // blanco. Sustituye a la banda carmesí: la misma calidez que el resto
          // de la app, y el nombre respira en vez de gritar.
          _hero(context, serif, profile.valueOrNull?.name, stars),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SETTINGS', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                _Group(children: [
                  _Row(
                    icon: CupertinoIcons.bell,
                    title: 'Daily notification',
                    subtitle: switch (notification.valueOrNull) {
                      null => 'Once a day',
                      (isEnabled: false, preferredTime: _) => 'Off',
                      final n => 'Once a day · ${n.preferredTime}',
                    },
                    onTap: () => context.go(AppRoutes.notification),
                  ),
                  _Row(
                    icon: Icons.track_changes,
                    title: 'My life areas',
                    subtitle: 'Me · Family · Relationships · Work',
                    onTap: () => context.go(AppRoutes.areas),
                  ),
                  _Row(
                    icon: Icons.record_voice_over_outlined,
                    title: 'How Aura speaks to you',
                    subtitle: 'Same warmth, your volume',
                    onTap: () => context.go(AppRoutes.messageStyle),
                  ),
                  _Row(
                    icon: Icons.translate_outlined,
                    title: 'Language',
                    subtitle: 'The language Aura speaks to you in',
                    onTap: () => context.go(AppRoutes.language),
                  ),
                  _Row(
                    icon: CupertinoIcons.calendar,
                    title: 'History',
                    subtitle: 'Your whole story',
                    onTap: () => context.go(AppRoutes.history),
                  ),
                  _Row(
                    icon: Icons.checklist,
                    title: 'All microhabits',
                    subtitle: 'Browse the full list',
                    onTap: () => context.go(AppRoutes.habits),
                  ),
                ]),
                const SizedBox(height: 22),
                // CUIDADO (Carril B): la ÚNICA superficie de care fuera de su
                // flujo. Discreta, sin badges ni contadores; el "aceptó" vive
                // aquí dentro — jamás en push (GUARD_CARE_09).
                const Text('CARE', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                _Group(children: [
                  _CareRow(),
                  // Círculo de Apoyo (Bloque 4): resumen semanal agregado a
                  // hasta 3 personas de confianza — jamás palabras ni día a día.
                  _Row(
                    icon: Icons.workspaces_outline,
                    title: 'My circle',
                    subtitle: 'Share your light — only if you want',
                    // push: al volver atrás regresa aquí (Profile), no al tab Care.
                    onTap: () => context.push(AppRoutes.supportCircle),
                  ),
                ]),
                const SizedBox(height: 22),
                // Premium quedó EXCLUIDO del producto (decisión jul 2026):
                // todo lo construido es para todas — sin fila "Go Premium".
                const Text('COMING SOON', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                _Group(children: [
                  _Row(
                    icon: Icons.nightlight_outlined,
                    title: 'My cycle',
                    titleBadge: 'v2',
                    subtitle: 'Advanced personalization',
                    onTap: () => context.go(AppRoutes.cycle),
                  ),
                ]),
                const SizedBox(height: 22),
                const Text('SESSION', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                _Group(children: [
                  _Row(
                    icon: CupertinoIcons.lock,
                    title: 'Change password',
                    subtitle: 'Signs you out on other devices',
                    onTap: () => context.go(AppRoutes.changePassword),
                  ),
                  _Row(
                    icon: CupertinoIcons.arrow_counterclockwise,
                    title: 'Restart onboarding',
                    subtitle: 'Answer again · your stars stay',
                    onTap: () => _confirmRestart(context, ref),
                  ),
                  _Row(
                    icon: CupertinoIcons.square_arrow_right,
                    title: 'Sign out',
                    subtitle: 'See you soon',
                    onTap: () => _confirmSignOut(context, ref),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hero del perfil: acuarela botánica anclada arriba-derecha que se difumina
  /// a blanco, con el saludo sobreimpreso a la izquierda y la insignia de
  /// estrella. Mismo lenguaje que Care y My circle.
  Widget _hero(
    BuildContext context,
    TextStyle serif,
    String? name,
    int? stars,
  ) {
    return SectionHero(
      asset: 'assets/images/care/profile_hero.png',
      child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'YOUR ACCOUNT',
                    style: TextStyle(
                      fontFamily: AppTypography.didot,
                      fontSize: 12,
                      letterSpacing: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'Hi, ',
                        style: serif.copyWith(
                          fontSize: 32,
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: name ?? '…',
                        style: serif.copyWith(
                          fontSize: 32,
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stars == null
                        ? 'Your sky is beginning ✦'
                        : '$stars ${stars == 1 ? 'star' : 'stars'} in your sky ✦',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Confirma y reinicia el onboarding. El servidor conserva el cielo
  /// (estrellas y constelaciones); el router la lleva de vuelta al flujo.
  Future<void> _confirmRestart(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAuraConfirm(
      context,
      title: 'Restart onboarding?',
      message: 'You will answer the first questions again. '
          'Your stars and constellations stay exactly as they are.',
      cancelLabel: 'Not now',
      confirmLabel: 'Restart',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(onboardingStatusProvider.notifier)
          .restartOnboarding(); // el router redirige a /onboarding
      // Datos del perfil quedan obsoletos: refrescar al volver a completar.
      ref.invalidate(profileProvider);
      ref.invalidate(notificationSettingsProvider);
    } on Failure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      }
    }
  }

  /// Confirma antes de cerrar sesión: un toque accidental no debe echarla.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAuraConfirm(
      context,
      title: 'Sign out?',
      message: "Your space stays just as you left it. You'll sign back in "
          'whenever you want.',
      cancelLabel: 'Stay',
      confirmLabel: 'Sign out',
    );
    if (!confirmed) return;
    await ref.read(authControllerProvider.notifier).logout();
  }
}

/// A1 · Fila CUIDADO: subtítulo según el momento del puente humano.
/// Verde sereno (no carmesí): el apoyo no es una tarea del día.
class _CareRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referral = ref.watch(careCurrentReferralProvider).valueOrNull;
    final name = referral?.providerName == null
        ? ''
        : shortProviderName(referral!.providerName!);
    final subtitle = switch (resolveCareView(referral)) {
      CareView.directory => 'People who can walk with you',
      CareView.sent => 'Request sent${name.isEmpty ? '' : ' to $name'}',
      CareView.responseAccepted =>
        '${name.isEmpty ? 'She said yes' : '$name said yes'} ✦',
      CareView.responseDeclined => 'You have a reply',
      CareView.episode =>
        'Your episode${name.isEmpty ? '' : ' with $name'} · ongoing',
    };
    final highlighted = referral != null && referral.providerResponse == 'accepted';

    return _Row(
      icon: Icons.volunteer_activism_outlined,
      title: 'Support from one person',
      subtitle: subtitle,
      iconColor: AppColors.careAccent,
      iconBackground: AppColors.careSurface,
      subtitleColor: highlighted ? AppColors.careAccent : null,
      onTap: () => context.push(AppRoutes.care),
    );
  }
}

/// Sección de ajustes: las filas van como cards INDEPENDIENTES, cada una con su
/// borde (no un card grande con divisores). Solo las apila.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(children: children);
}

/// Fila de ajuste del maquetado: icono CARMESÍ en cápsula rosa + título +
/// subtítulo + chevron.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.titleBadge,
    this.onTap,
    this.iconColor,
    this.iconBackground,
    this.subtitleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? titleBadge;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackground;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    // Card independiente: borde propio y separación con la siguiente fila.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground ?? AppColors.roseTint,
                // Cápsula de esquinas REDONDEADAS (no círculo): mismo lenguaje
                // que los iconos de Care y Notificaciones.
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (titleBadge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.selectedRose,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            titleBadge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: subtitleColor ?? AppColors.textSecondary,
                      fontWeight: subtitleColor == null
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 20, color: AppColors.textSecondary),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
