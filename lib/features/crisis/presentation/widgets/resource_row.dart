import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../domain_export.dart';
import '../providers/crisis_provider.dart';

/// Una fila llamable. Un toque abre el marcador con el número puesto; ella
/// decide si pulsa llamar.
///
/// La emergencia (112) se pinta más callada que una línea de escucha: no debe
/// competir visualmente con quien atiende a alguien que solo necesita hablar.
class ResourceRow extends StatelessWidget {
  const ResourceRow({super.key, required this.resource});

  final CrisisResource resource;

  @override
  Widget build(BuildContext context) {
    final isListening = resource.kind == CrisisResourceKind.listening;
    final iconColor =
        isListening ? AppColors.primary : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => dialNumber(resource.phone),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                isListening ? Icons.phone_outlined : Icons.emergency_outlined,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      resource.note == null
                          ? resource.phone
                          : '${resource.phone} · ${resource.note}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
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
