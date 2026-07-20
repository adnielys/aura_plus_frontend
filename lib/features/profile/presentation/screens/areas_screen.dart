import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../check_in/presentation/providers/areas_presence_provider.dart';
import '../providers/profile_provider.dart';

/// Estilo e identidad de cada área (Documento Maestro §06 — definiciones
/// EXACTAS). Mismos tonos que las HabitCards.
typedef _AreaInfo = ({String name, String what, Color bg, Color fg, IconData icon});

const Map<HabitArea, _AreaInfo> _areaInfo = {
  HabitArea.self: (
    name: 'Me',
    what: 'Rest, body, mind, personal time.',
    bg: Color(0xFFFFE3EE),
    fg: Color(0xFFC01448),
    icon: Icons.self_improvement,
  ),
  HabitArea.family: (
    name: 'Family',
    what: 'Kids, home, partner, presence.',
    bg: Color(0xFFFCE9D6),
    fg: Color(0xFFE0894A),
    icon: Icons.auto_stories,
  ),
  HabitArea.relationships: (
    name: 'Relationships',
    what: 'Friendships, bonds, community.',
    bg: Color(0xFFECE1FB),
    fg: Color(0xFF9B6FD4),
    icon: Icons.favorite_border,
  ),
  HabitArea.work: (
    name: 'Work',
    what: 'Career, projects, learning.',
    bg: Color(0xFFDCE9F6),
    fg: Color(0xFF3F7CB0),
    icon: Icons.work_outline,
  ),
};

/// "Lo que más te pesa" (M2): valores del onboarding, en su idioma.
const List<(MainPain, String)> _painOptions = [
  (MainPain.self, 'Me'),
  (MainPain.family, 'My family and home'),
  (MainPain.relationships, 'My relationships'),
  (MainPain.work, 'Work'),
  (MainPain.all, 'Everything at once'),
];

/// Mis áreas (M1+M2): pantalla CONTEMPLATIVA — qué es cada área, dónde hubo
/// presencia este ciclo, y la puerta a lo que ella se ha regalado (M3).
/// Jamás un dashboard: sin %, sin metas, sin "te falta" (Documento Maestro
/// §08 + GUARD_TONE_03/04). Aura equilibra por ella.
class AreasScreen extends ConsumerStatefulWidget {
  const AreasScreen({super.key});

  @override
  ConsumerState<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends ConsumerState<AreasScreen> {
  bool _savingPain = false;

  @override
  void initState() {
    super.initState();
    // Presencia fresca al entrar (misma luz que el Home).
    Future.microtask(() {
      if (mounted) ref.invalidate(areasPresenceProvider);
    });
  }

  Future<void> _setPain(MainPain pain) async {
    if (_savingPain) return;
    setState(() => _savingPain = true);
    try {
      await updateMainPain(ref, pain);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save it. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPain = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lit = ref.watch(areasPresenceProvider).valueOrNull ?? const {};
    final mainPain = ref.watch(profileProvider).valueOrNull?.mainPain;
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go(AppRoutes.profile),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new,
                        size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text('Profile',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('MY LIFE AREAS', style: AppTypography.sectionLabel),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: 'The map of your life, ', style: serif),
                TextSpan(
                  text: 'no goals.',
                  style: serif.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your day spreads its light across these four. Aura balances '
              "them for you — you don't have to keep score.",
              style: TextStyle(
                  fontSize: 12.5, height: 1.55, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            for (final area in HabitArea.values)
              _AreaCard(
                area: area,
                info: _areaInfo[area]!,
                lit: lit.contains(area),
              ),
            const SizedBox(height: 12),
            // M2 · Lo que más te pesa ahora (main_pain del onboarding, vivo).
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WHAT WEIGHS ON YOU MOST NOW',
                      style: AppTypography.sectionLabel),
                  const SizedBox(height: 4),
                  const Text(
                    'You told me when you arrived. If it changed, change it — '
                    'no questions, no whys.',
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final (pain, label) in _painOptions)
                        ChoiceChip(
                          label: Text(label),
                          selected: mainPain == pain,
                          onSelected:
                              _savingPain ? null : (_) => _setPain(pain),
                          showCheckmark: false,
                          selectedColor: const Color(0xFFFCE3EC),
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: mainPain == pain
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: mainPain == pain
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          side: BorderSide(
                            color: mainPain == pain
                                ? const Color(0xFFF0C3D3)
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "This only helps me walk with you better. It doesn't change "
              'your stars or ask anything of you.',
              style: TextStyle(
                  fontSize: 10.5, height: 1.5, color: Color(0xFFA79FAD)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.info, required this.lit});

  final HabitArea area;
  final _AreaInfo info;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(AppRoutes.areaGestures, extra: area),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: info.bg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(info.icon, size: 18, color: info.fg),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    info.name,
                    style: const TextStyle(
                      fontFamily: AppTypography.serif,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: lit
                          ? const Color(0xFFFCE3EC)
                          : AppColors.surfaceTint,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      lit ? '✦ lit this cycle' : 'still at rest',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: lit ? FontWeight.w700 : FontWeight.w400,
                        color: lit
                            ? AppColors.primary
                            : const Color(0xFFB9AFC2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                info.what,
                style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                "What you've given yourself here ›",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: info.fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
