import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/crisis_provider.dart';
import '../widgets/resource_row.dart';

/// Ayuda inmediata: entra por su propio pie, sin haber escrito nada.
///
/// No depende del acompañante ni de la red (ver [crisisHelpProvider]). Sin
/// alarma, sin rojo: acompaña, no diagnostica.
class RightNowScreen extends ConsumerWidget {
  const RightNowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final help = ref.watch(crisisHelpProvider);
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 19,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        );

    return Scaffold(
      body: help.when(
        // Ni siquiera el estado de carga puede quedarse en blanco mucho: el
        // provider resuelve local si no hay red.
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
          children: [
            const Text('RIGHT NOW', style: AppTypography.sectionLabel),
            const SizedBox(height: 12),
            Text(data.intro, style: serif),
            const SizedBox(height: 18),
            for (final resource in data.resources)
              ResourceRow(resource: resource),
            const SizedBox(height: 10),
            Text(
              data.closing,
              style: serif.copyWith(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.profile),
                child: const Text(
                  '← Back',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
