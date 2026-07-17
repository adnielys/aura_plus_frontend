import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/domain/enums.dart';
import '../../../../shared/widgets/habit_icons.dart';
import '../../domain/entities/check_in_result.dart';

/// Micro-card del maquetado, compartida por la reco y el Home: icono del
/// HÁBITO en cápsula, título, meta, pill del área a la derecha, ⇄ para
/// sustituir y la franja Done | Not today. Con el día CERRADO
/// ([closedResult]), la opción registrada se pinta TACHADA.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.result,
    required this.onMark,
    this.onSwap,
    this.closedResult,
  });

  final Habit habit;

  /// Marca local (borrador) antes de cerrar el día.
  final HabitResult? result;
  final ValueChanged<HabitResult> onMark;

  /// Abre el banco en modo sustitución (null = marcada o día cerrado).
  final VoidCallback? onSwap;

  /// Resultado registrado en el cierre (del servidor): chips tachadas.
  final HabitResult? closedResult;

  /// Colores por área (AREA del maquetado). El icono es del HÁBITO
  /// ([habitIconData]); el área solo pone el color, como en el maquetado.
  static const _areaStyle = {
    HabitArea.self: (Color(0xFFFFE3EE), Color(0xFFC01448), Color(0xFFFFF0F4)),
    HabitArea.family: (Color(0xFFFCE9D6), Color(0xFFE0894A), Color(0xFFFFF6EE)),
    HabitArea.relationships: (Color(0xFFECE1FB), Color(0xFF9B6FD4),
        Color(0xFFF6F0FF)),
    HabitArea.work: (Color(0xFFDCE9F6), Color(0xFF3F7CB0), Color(0xFFEEF5FC)),
  };

  /// Etiqueta EN del área (zona reco del maquetado).
  static const _areaLabel = {
    HabitArea.self: 'Me',
    HabitArea.family: 'Family',
    HabitArea.relationships: 'Relationships',
    HabitArea.work: 'Work',
  };

  @override
  Widget build(BuildContext context) {
    final (tagBg, tagFg, iconBg) = _areaStyle[habit.area]!;
    final icon = habitIconData(habit.icon, habit.area);
    final closed = closedResult != null;
    final isDone =
        closed ? closedResult == HabitResult.done : result == HabitResult.done;
    final marked = closed || result != null;

    // Métrica exacta del maquetado (micro-card): borde --border 1px, radio 18,
    // icono 38/r12, título 14 w700, meta 11. Al marcar: la franja desaparece,
    // el meta registra la elección y "Done" atenúa la tarjeta con tachado.
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDone && !closed ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 11),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: tagFg),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary.withValues(
                                alpha: closed ? 0.75 : 1),
                            decoration: isDone && !closed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          closed
                              ? '${habit.durationMinutes} min · Registrado'
                              : marked
                                  ? 'Elegido: ${result!.label}'
                                  : '${habit.durationMinutes} min · pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                marked && !closed
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                            color: marked && !isDone && !closed
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      _areaLabel[habit.area]!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tagFg,
                      ),
                    ),
                  ),
                  if (onSwap != null) ...[
                    const SizedBox(width: 8),
                    // ⇄ del maquetado: cambiarlo por otro del banco.
                    InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: onSwap,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.swap_horiz,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (closed)
              // Día cerrado: lo elegido queda tachado (gesto registrado ✓);
              // "No fue posible" también — registrar ya es el logro.
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 13),
                child: Row(
                  children: [
                    for (final option in HabitResult.values) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: option == closedResult
                              ? const Color(0xFFFCE3EC)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: option == closedResult
                                ? Colors.transparent
                                : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: option == closedResult
                                ? AppColors.primary
                                : const Color(0xFFC9C2CE),
                            decoration: option == closedResult
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.primary,
                            decorationThickness: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              )
            else if (!marked)
              // Franja de confirmación (confirm-strip): desaparece al marcar.
              // Las MISMAS 3 opciones que pinta el cierre, para que antes y
              // después coincidan ("A medias" también suma, filosofía).
              Container(
                decoration: const BoxDecoration(
                  border:
                      Border(top: BorderSide(color: AppColors.surfaceTint)),
                ),
                child: Row(
                  children: [
                    for (final (index, option)
                        in HabitResult.values.indexed) ...[
                      if (index > 0)
                        Container(
                            width: 1,
                            height: 42,
                            color: AppColors.surfaceTint),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.only(
                            bottomLeft: index == 0
                                ? const Radius.circular(18)
                                : Radius.zero,
                            bottomRight:
                                index == HabitResult.values.length - 1
                                    ? const Radius.circular(18)
                                    : Radius.zero,
                          ),
                          onTap: () => onMark(option),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: option == HabitResult.done
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
