import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Chip de selección tipo "pill" del maquetado.
///
/// No seleccionado: lila muy suave. Seleccionado: fondo rosa + borde y texto
/// magenta en negrita. Sirve para elección única (sentimiento, tiempo, momento)
/// y múltiple (edades de los hijos); el padre decide la semántica.
class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _idleBackground = Color(0xFFF8F4FC);
  static const Color _idleBorder = Color(0xFFE8E0F0);
  static const Color _idleText = Color(0xFF5A4F6A);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? EmotionalStateColors.energy.background
                : _idleBackground,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: selected ? AppColors.primary : _idleBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : _idleText,
            ),
          ),
        ),
      ),
    );
  }
}
