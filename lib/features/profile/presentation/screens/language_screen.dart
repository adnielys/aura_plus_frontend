import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../providers/profile_provider.dart';

/// En qué idioma le habla Aura. Un tap = PATCH /profile, sin preguntas ni
/// confirmaciones (mismo espíritu que la voz de Aura y "lo que más te pesa").
///
/// Se propone desde el idioma del teléfono la primera vez; desde que ella
/// toca aquí, manda su elección para siempre.
///
/// HONESTIDAD: hoy esto cambia los textos que vienen del SERVIDOR (la
/// conversación con Aura). La interfaz sigue en inglés mientras se traduce, y
/// la nota al pie lo dice — prometer menos y cumplir.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

    return Scaffold(
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
          children: [
            const Text('LANGUAGE', style: AppTypography.sectionLabel),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: 'The language ', style: serif),
                TextSpan(
                  text: 'Aura speaks to you in.',
                  style: serif.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            for (final lang in AppLanguage.values) ...[
              _LanguageOption(
                lang: lang,
                selected: data.lang == lang,
                onTap: () => updateLanguage(ref, lang),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Aura writes to you in this language. The app itself is still '
                'in English while we translate it, carefully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.textSecondary),
              ),
            ),
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

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8FA) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.largecircle_fill_circle
                  : CupertinoIcons.circle,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              lang.label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
