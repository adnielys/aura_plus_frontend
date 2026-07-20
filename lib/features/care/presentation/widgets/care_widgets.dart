import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/care_providers.dart';

/// Piezas visuales del flujo care. Verde sereno (#3E7C7B) para el apoyo,
/// lila para lo clínico — nunca el carmesí de la acción diaria.

/// Vuelta al perfil (el flujo care cuelga de la fila CUIDADO).
class CareBackRow extends StatelessWidget {
  const CareBackRow({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de nivel del directorio (Apoyo / Clínico).
class CareTierLabel extends StatelessWidget {
  const CareTierLabel({super.key, required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    final clinical = tier == 'clinical';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: clinical ? AppColors.clinicalSurface : AppColors.careSurface,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          clinical ? 'CLINICAL' : 'SUPPORT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: clinical ? AppColors.clinicalAccent : AppColors.careAccent,
          ),
        ),
      ),
    );
  }
}

/// Línea meta de un profesional: especialidades · idiomas · verificación.
String providerMetaLine(CareProviderInfo provider) {
  final parts = [
    if (provider.specialties.isNotEmpty) provider.specialties.take(2).join(' · '),
    provider.languages.map((l) => l.toUpperCase()).join(' / '),
    if (provider.licenseVerified) '✓ licensed & verified' else '✓ verified',
  ];
  return parts.join(' · ');
}

/// Buscador del directorio (D1/D2): nombre, tipo o especialidad.
class CareSearchField extends StatelessWidget {
  const CareSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search by name or type — doula, psychologist…',
          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFB9AFC2)),
          prefixIcon: const Icon(Icons.search,
              size: 18, color: Color(0xFFB9AFC2)),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: Color(0xFFB9AFC2)),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide:
                const BorderSide(color: AppColors.careBorder, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Chips de filtro por nivel: Todas / Apoyo / Clínico (se combinan con el
/// buscador).
class CareTierChips extends StatelessWidget {
  const CareTierChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  /// null = Todas · 'support' · 'clinical'
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String? value) {
      final on = selected == value;
      final clinical = value == 'clinical';
      return Padding(
        padding: const EdgeInsets.only(right: 7),
        child: ChoiceChip(
          label: Text(label),
          selected: on,
          onSelected: enabled ? (_) => onSelected(value) : null,
          showCheckmark: false,
          selectedColor:
              clinical ? AppColors.clinicalSurface : AppColors.careSurface,
          backgroundColor: AppColors.surface,
          labelStyle: TextStyle(
            fontSize: 11.5,
            fontWeight: on ? FontWeight.w700 : FontWeight.w400,
            color: on
                ? (clinical ? AppColors.clinicalAccent : AppColors.careAccent)
                : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: on
                ? (clinical ? const Color(0xFFDCCDEF) : AppColors.careBorder)
                : AppColors.border,
            width: 1.5,
          ),
        ),
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Row(
        children: [
          chip('All', null),
          chip('Support', 'support'),
          chip('Clinical', 'clinical'),
        ],
      ),
    );
  }
}

/// Badge 📤 del card con petición enviada (D3).
class CareSentBadge extends StatelessWidget {
  const CareSentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.careSurface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.careBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.send_rounded, size: 12, color: AppColors.careAccent),
          SizedBox(width: 4),
          Text(
            'sent',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.careAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Franja "una persona a la vez" del directorio en reposo (D3).
class CareLockBanner extends StatelessWidget {
  const CareLockBanner({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CareDoveSmall(),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: 'One person at a time. ',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: 'Your request to $name is still in her hands — '
                      'while you wait, the rest of the directory rests.',
                ),
              ]),
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paloma pequeña teñida (franja D3).
class CareDoveSmall extends StatelessWidget {
  const CareDoveSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColorFiltered(
      colorFilter: ColorFilter.mode(AppColors.careAccent, BlendMode.srcIn),
      child: Text('🕊', style: TextStyle(fontSize: 15)),
    );
  }
}

/// Tarjeta de profesional: avatar con inicial + nombre + meta.
class CareProviderCard extends StatelessWidget {
  const CareProviderCard({
    super.key,
    required this.name,
    required this.meta,
    required this.tier,
    this.metaColor,
    this.trailing,
    this.highlighted = false,
  });

  final String name;
  final String meta;
  final String tier;
  final Color? metaColor;
  final Widget? trailing;

  /// Borde verde suave: el card de la petición enviada (D3).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final clinical = tier == 'clinical';
    final accent =
        clinical ? AppColors.clinicalAccent : AppColors.careAccent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFBFDFD) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? AppColors.careBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Text(
              name.isEmpty ? '·' : name.characters.first.toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(
                      fontSize: 11,
                      color: metaColor ?? AppColors.textSecondary,
                      fontWeight:
                          metaColor == null ? FontWeight.w400 : FontWeight.w700),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Tarjeta verde con el contacto del profesional (solo existe tras su "sí").
class CareContactCard extends StatelessWidget {
  const CareContactCard({super.key, required this.contact, required this.note});

  final Map<String, Object?>? contact;
  final String note;

  @override
  Widget build(BuildContext context) {
    final value = contact?['value'] as String?;
    final type = contact?['type'] as String?;
    final icon = switch (type) {
      'phone' => '📞',
      _ => '✉',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.careSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.careBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value == null ? '$icon Her contact will appear here' : '$icon $value',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF173B3A)),
          ),
          const SizedBox(height: 4),
          Text(note,
              style: TextStyle(
                  fontSize: 10.5,
                  height: 1.5,
                  color: const Color(0xFF173B3A).withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

/// Pasos del episodio: SOLO lo andado se enciende; el cierre nunca presiona.
class CareSteps extends StatelessWidget {
  const CareSteps({super.key, required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Request', true),
      ('She said yes', true),
      ('Connected', connected),
      ('Closure', false),
    ];
    return Row(
      children: [
        for (final (label, done) in steps)
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        done ? AppColors.careSurface : AppColors.surfaceTint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    done ? '✓' : '·',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: done
                          ? AppColors.careAccent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    color: done
                        ? AppColors.careAccent
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Paloma del mockup A4: el emoji teñido de verde sereno (silueta plana),
/// nunca el emoji a color del sistema.
class CareDove extends StatelessWidget {
  const CareDove({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColorFiltered(
      colorFilter: ColorFilter.mode(AppColors.careAccent, BlendMode.srcIn),
      child: Text('🕊', style: TextStyle(fontSize: 36)),
    );
  }
}

/// Botón principal del flujo care, a ancho completo como el mockup.
/// Verde por defecto; [crimson] = degradado carmesí de la zona de entrada
/// (volver al espacio diario / cerrar capítulo); [outlined] para acciones
/// serenas no-principales.
class CarePrimaryButton extends StatelessWidget {
  const CarePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.crimson = false,
    this.outlined = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool crimson;
  final bool outlined;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));

    if (outlined) {
      return OutlinedButton(
        onPressed: busy ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.careAccent,
          side: const BorderSide(color: AppColors.careBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: child,
      );
    }
    if (crimson) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.entryGradient,
          borderRadius: BorderRadius.circular(26),
        ),
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: child,
        ),
      );
    }
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.careAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      child: child,
    );
  }
}
