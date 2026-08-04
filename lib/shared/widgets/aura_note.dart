import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Nota con la VOZ de Aura: fondo oscuro con resplandor, glifo en cápsula clara
/// y texto en serif itálica. Se usa para las promesas de la app (privacidad en
/// Care, el silencio sin castigo en las notificaciones) — nunca para avisos de
/// error ni para instrucciones.
///
/// El [title] va como lista de spans para poder resaltar la palabra clave en
/// rosa, como "privacy" en la nota de Care.
class AuraNote extends StatelessWidget {
  const AuraNote({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  /// Glifo dentro de la cápsula redonda (un icono, un ✦…).
  final Widget icon;
  final List<InlineSpan> title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Mismo degradado con resplandor que el aura-message del maquetado.
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0820), Color(0xFF4A0828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.roseTint,
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(children: title),
                  style: const TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
