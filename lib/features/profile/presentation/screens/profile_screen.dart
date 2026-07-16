import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../constellation/presentation/providers/constellation_provider.dart';
import '../providers/profile_provider.dart';

/// Perfil (maquetado · tab "perfil"): cabecera con degradado carmesí,
/// SETTINGS y PLAN con iconos carmesí en cápsula rosa.
/// Adaptación de filosofía: el maquetado decía "days of continuous presence"
/// (una racha) — aquí se muestra la presencia ACUMULADA del cielo, que nunca
/// se rompe ni castiga el silencio.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final constellation = ref.watch(currentConstellationProvider);
    final notification = ref.watch(notificationSettingsProvider);
    final serif = Theme.of(context).textTheme.headlineMedium!;
    final stars = constellation.valueOrNull?.starsEarned;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Cabecera con el degradado del maquetado (plum → carmesí).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 54, 24, 26),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A0A22), Color(0xFF7A0B30), Color(0xFFB01046)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR ACCOUNT',
                  style: TextStyle(
                    fontFamily: AppTypography.didot,
                    fontSize: 12,
                    letterSpacing: 2,
                    color: Color(0xFFD9A8BE),
                  ),
                ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: 'Hi, ',
                      style: serif.copyWith(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text: profile.valueOrNull?.name ?? '…',
                      style: serif.copyWith(
                        color: AppColors.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                Text(
                  stars == null
                      ? 'Your sky is beginning ✦'
                      : '$stars ${stars == 1 ? 'star' : 'stars'} in your sky ✦',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SETTINGS', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                _Row(
                  icon: Icons.notifications_none,
                  title: 'Daily notification',
                  subtitle: switch (notification.valueOrNull) {
                    null => 'Once a day',
                    final n => 'Once a day · ${n.preferredTime}',
                  },
                ),
                const _Row(
                  icon: Icons.track_changes,
                  title: 'My life areas',
                  subtitle: 'Me · Family · Relationships · Work',
                ),
                const _Row(
                  icon: Icons.calendar_today_outlined,
                  title: 'History',
                  subtitle: 'Last 28 days',
                ),
                const _Row(
                  icon: Icons.checklist,
                  title: 'All microhabits',
                  subtitle: 'Browse the full list',
                ),
                const SizedBox(height: 18),
                const Text('PLAN', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                const _Row(
                  icon: Icons.diamond_outlined,
                  title: 'Go Premium',
                  subtitle: 'Galaxy · cycle · Aura tells you · wearables',
                ),
                _Row(
                  icon: Icons.nightlight_outlined,
                  title: 'My cycle',
                  titleBadge: 'v2',
                  subtitle: 'Advanced personalization',
                  onTap: () => context.go(AppRoutes.cycle),
                ),
                const SizedBox(height: 18),
                const Text('SESSION', style: AppTypography.sectionLabel),
                const SizedBox(height: 10),
                _Row(
                  icon: Icons.logout,
                  title: 'Sign out',
                  subtitle: 'See you soon',
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? titleBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
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
                            color: const Color(0xFFFCE3EC),
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
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
