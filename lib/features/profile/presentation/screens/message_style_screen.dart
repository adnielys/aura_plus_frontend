import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/aura_note.dart';
import '../../../../shared/widgets/section_hero.dart';
import '../providers/profile_provider.dart';

/// Cómo le habla Aura (Bloque 2 · Q4): selector de voz con ejemplo por opción.
/// Un tap = PATCH /profile; cambiable cuando quiera, sin preguntas ni
/// confirmaciones (mismo espíritu que "Lo que más te pesa ahora").
class MessageStyleScreen extends ConsumerWidget {
  const MessageStyleScreen({super.key});

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
              asset: 'assets/images/care/voice_hero.png',
              eyebrow: 'HOW AURA SPEAKS TO YOU',
              title: [
                const TextSpan(text: 'Same warmth, '),
                TextSpan(
                  text: 'your volume.',
                  style: serif.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.primary),
                ),
              ],
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.profile),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            const Text(
              'Aura never judges — but you choose how she wraps her words.',
              style: TextStyle(
                  fontSize: 13.5, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            for (final (i, style) in MessageStyle.values.indexed) ...[
              _StyleOption(
                style: style,
                leafAsset: _leafAssets[i % _leafAssets.length],
                selected: data.messageStyle == style,
                onTap: () => updateMessageStyle(ref, style),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            const AuraNote(
              icon: Text('✦',
                  style: TextStyle(fontSize: 17, color: AppColors.primary)),
              title: [
                TextSpan(text: 'Change it '),
                TextSpan(
                    text: 'whenever you want',
                    style: TextStyle(color: AppColors.secondary)),
                TextSpan(text: '.'),
              ],
              subtitle: 'No questions asked.',
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

/// Acuarela de fondo por opción, en el orden del enum: rosa para la voz
/// cálida, teal para la breve y la mixta para la que explica el porqué.
const _leafAssets = [
  'assets/images/care/card2.png',
  'assets/images/care/card1.png',
  'assets/images/care/card3.png',
];

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.leafAsset,
    required this.selected,
    required this.onTap,
  });

  final MessageStyle style;
  final String leafAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF8FA) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Hojas al 22% DETRÁS del texto, ancladas a la derecha (mismo
              // tratamiento que las puertas del tab Care).
              Positioned.fill(
                child: Image.asset(
                  leafAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topRight,
                  opacity: const AlwaysStoppedAnimation(0.22),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? CupertinoIcons.largecircle_fill_circle
                      : CupertinoIcons.circle,
                  size: 18,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  style == MessageStyle.warm
                      ? '${style.label} (default)'
                      : style.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                style.description,
                style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(left: 26),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                style.example,
                style: const TextStyle(
                  fontFamily: AppTypography.serif,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF4A4253),
                ),
              ),
            ),
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
