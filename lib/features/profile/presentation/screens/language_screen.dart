import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/aura_note.dart';
import '../../../../shared/widgets/section_hero.dart';
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
      backgroundColor: AppColors.background,
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileProvider),
            child: const Text('Try again'),
          ),
        ),
        data: (data) => ListView(
          padding: EdgeInsets.zero,
          children: [
            SectionHeader(
              asset: 'assets/images/care/language_hero.png',
              eyebrow: 'LANGUAGE',
              title: [
                const TextSpan(text: 'The language '),
                TextSpan(
                  text: 'Aura speaks to you in.',
                  style: serif.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.primary),
                ),
              ],
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.profile),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            for (final lang in AppLanguage.values) ...[
              _LanguageOption(
                lang: lang,
                selected: data.lang == lang,
                onTap: () => updateLanguage(ref, lang),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            const AuraNote(
              icon: Text('✦',
                  style: TextStyle(fontSize: 17, color: AppColors.primary)),
              title: [
                TextSpan(text: 'Aura writes to you in '),
                TextSpan(
                    text: 'this language',
                    style: TextStyle(color: AppColors.secondary)),
                TextSpan(text: '.'),
              ],
              subtitle: 'The app itself is still in English while we '
                  'translate it, carefully.',
            ),
                ],
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
