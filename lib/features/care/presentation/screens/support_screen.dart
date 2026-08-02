import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/care_providers.dart';

/// Tab "Support": reúne el cuidado humano (Carril B) que antes vivía en el
/// Profile → CARE. Dos puertas: apoyo de UNA persona y el círculo de apoyo.
/// Discreto, opt-in, sin badges ni contadores (GUARD_CARE_09: jamás push).
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    // Polling suave (mismo patrón que el resto de tabs): refresca al entrar.
    Future.microtask(() {
      if (mounted) ref.invalidate(careCurrentReferralProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            const Text('CARE', style: AppTypography.sectionLabel),
            const SizedBox(height: 10),
            Text("You don't have to walk alone.", style: serif),
            const SizedBox(height: 6),
            const Text(
              'People who can be there — only if and when you want. '
              'Nothing is shared without your say.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.6, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            // Apoyo de UNA persona (Carril B). El estado "aceptó" vive dentro
            // del propio flujo, nunca en push.
            _SupportRow(
              icon: Icons.volunteer_activism_outlined,
              iconColor: AppColors.careAccent,
              iconBackground: AppColors.careSurface,
              title: 'Support from one person',
              subtitle: 'People who can walk with you',
              onTap: () => context.go(AppRoutes.care),
            ),
            // Círculo de apoyo: resumen a hasta 3 personas de confianza.
            _SupportRow(
              icon: Icons.workspaces_outline,
              title: 'My circle',
              subtitle: 'Share your light — only if you want',
              onTap: () => context.go(AppRoutes.supportCircle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila del maquetado: icono en cápsula + título + subtítulo + chevron.
class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? iconBackground;

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
                color: iconBackground ?? AppColors.roseTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
