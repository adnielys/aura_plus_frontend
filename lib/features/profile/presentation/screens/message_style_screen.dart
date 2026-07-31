import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
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
            const Text('HOW AURA SPEAKS TO YOU',
                style: AppTypography.sectionLabel),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Same warmth, ', style: serif),
                TextSpan(
                  text: 'your volume.',
                  style: serif.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aura never judges — but you choose how she wraps her words.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            for (final style in MessageStyle.values) ...[
              _StyleOption(
                style: style,
                selected: data.messageStyle == style,
                onTap: () => updateMessageStyle(ref, style),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Change it whenever you want — no questions asked.',
                style:
                    TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final MessageStyle style;
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
    );
  }
}
