import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/utils/dates.dart';
import '../../../../shared/widgets/habit_icons.dart';
import '../providers/area_gestures_provider.dart';

/// Colores por área (mismos tonos que las HabitCards) + nombre en español.
const Map<HabitArea, (Color bg, Color fg, String name)> _areaStyle = {
  HabitArea.self: (Color(0xFFFFE3EE), Color(0xFFC01448), 'Yo'),
  HabitArea.family: (Color(0xFFFCE9D6), Color(0xFFE0894A), 'Familia'),
  HabitArea.relationships: (Color(0xFFECE1FB), Color(0xFF9B6FD4), 'Relaciones'),
  HabitArea.work: (Color(0xFFDCE9F6), Color(0xFF3F7CB0), 'Trabajo'),
};

/// M3 · "Lo que te has regalado en {área}": gestos REGISTRADOS de los últimos
/// 28 días. Solo presencia — sin huecos, sin "días sin", sin totales de
/// fallo; "no fue posible" con la misma dignidad (registrarlo ya fue cuidarse).
class AreaGesturesScreen extends ConsumerStatefulWidget {
  const AreaGesturesScreen({super.key, required this.area});

  final HabitArea area;

  @override
  ConsumerState<AreaGesturesScreen> createState() => _AreaGesturesScreenState();
}

class _AreaGesturesScreenState extends ConsumerState<AreaGesturesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.invalidate(areaGesturesProvider(widget.area));
    });
  }

  @override
  Widget build(BuildContext context) {
    final gestures = ref.watch(areaGesturesProvider(widget.area));
    final (_, fg, name) = _areaStyle[widget.area]!;
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
              onTap: () => context.go(AppRoutes.areas),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new,
                        size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text('Mis áreas',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('${name.toUpperCase()} · TUS GESTOS',
                style: AppTypography.sectionLabel),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Lo que te has regalado ', style: serif),
                TextSpan(
                  text: 'en $name.',
                  style: serif.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            const Text(
              'Los últimos 28 días. Todo lo registrado vive aquí — también '
              'lo que no fue posible: registrarlo ya fue cuidarte.',
              style: TextStyle(
                  fontSize: 12, height: 1.55, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            ...gestures.when(
              loading: () => const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
              error: (_, _) => [
                Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(areaGesturesProvider(widget.area)),
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
              data: (rows) => rows.isEmpty
                  ? [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Aún en calma.\nCuando registres un gesto de $name, '
                          'vivirá aquí.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.6,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ]
                  : [
                      for (final gesture in rows)
                        _GestureRow(gesture: gesture, fg: fg),
                    ],
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go(AppRoutes.habits, extra: widget.area),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Explorar el banco de $name ›',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
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

class _GestureRow extends ConsumerWidget {
  const _GestureRow({required this.gesture, required this.fg});

  final AreaGesture gesture;
  final Color fg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (bg, _, _) = _areaStyle[gesture.area]!;
    // Chip del resultado: los tres con dignidad — jamás rojo de error.
    final (chipBg, chipFg) = switch (gesture.result) {
      HabitResult.done => (const Color(0xFFFCE3EC), AppColors.primary),
      HabitResult.partial => (const Color(0xFFFFF6E8), const Color(0xFFB07A2D)),
      HabitResult.notPossible => (
          AppColors.surfaceTint,
          AppColors.textSecondary
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(habitIconData(gesture.icon, gesture.area),
                size: 16, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gesture.title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relativeSpanishDate(gesture.date, DateTime.now()),
                  style: const TextStyle(
                      fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              gesture.result.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: chipFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
