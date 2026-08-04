import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/aura_note.dart';
import '../../../../shared/widgets/section_hero.dart';
import '../providers/profile_provider.dart';

/// Ajustes de la única notificación diaria (fila "Daily notification").
/// GUARD_NOTIF_03: máximo un mensaje al día — aquí solo se elige CUÁNDO
/// llega (o si llega), nunca cuántos.
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _saving = false;

  Future<void> _update({bool? isEnabled, String? preferredTime}) async {
    setState(() => _saving = true);
    try {
      await updateNotificationSettings(
        ref,
        isEnabled: isEnabled,
        preferredTime: preferredTime,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("We couldn't save the change.")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted = '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    await _update(preferredTime: formatted);
  }

  /// Vuelve a DONDE se entró; el go a Profile solo es red de seguridad.
  void _goBack() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.profile);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // El margen superior lo aplica la cabecera (SectionHero): aquí solo
          // hace falta el inferior.
          SafeArea(
            top: false,
            child: settings.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () =>
                      ref.invalidate(notificationSettingsProvider),
                  child: const Text('Try again'),
                ),
              ),
              data: (value) => ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Cabecera ESTÁNDAR (220dp): acuarela propia con el reloj.
                  SectionHero(
                    asset: 'assets/images/care/notification_hero.png',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  size: 24, color: AppColors.textPrimary),
                              tooltip: 'Back',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              onPressed: _goBack,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DAILY NOTIFICATION',
                                    style: AppTypography.sectionLabel
                                        .copyWith(color: AppColors.primary)),
                                const SizedBox(height: 8),
                                // Ancho acotado: el titular baja a dos líneas y
                                // deja la derecha libre para la botánica.
                                FractionallySizedBox(
                                  widthFactor: 0.62,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'A gentle daily pause',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium!
                                        .copyWith(
                                          fontSize: 32,
                                          height: 1.15,
                                          color: AppColors.textPrimary,
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  const FractionallySizedBox(
                    widthFactor: 0.85,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'One message a day, at this moment. Nothing more.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bloque agrupado: las dos opciones viven en un mismo card,
                  // separadas por un filete — son un solo ajuste.
                  _Group(children: [
                    _SettingRow(
                      icon: Icons.notifications_active_outlined,
                      iconColor: AppColors.primary,
                      iconBackground: AppColors.roseTint,
                      title: 'Daily message',
                      subtitle: value.isEnabled ? 'On · once a day' : 'Off',
                      trailing: Switch(
                        value: value.isEnabled,
                        onChanged:
                            _saving ? null : (on) => _update(isEnabled: on),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                    ),
                    const _GroupDivider(),
                    _SettingRow(
                      icon: Icons.access_time_rounded,
                      iconColor: AppColors.careAccent,
                      iconBackground: AppColors.careSurface,
                      title: 'Delivery time',
                      subtitle: 'Tap to change',
                      // Sin el mensaje diario la hora no aplica: se apaga.
                      enabled: value.isEnabled && !_saving,
                      onTap: () => _pickTime(value.preferredTime),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.selectedRose,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          value.preferredTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // La promesa de la app, con la voz de Aura (mismo estilo que
                  // la nota de privacidad en Care): el silencio no se penaliza
                  // — ni rachas ni "días sin abrir".
                  const AuraNote(
                    icon: Text('✦',
                        style:
                            TextStyle(fontSize: 17, color: AppColors.primary)),
                    title: [
                      TextSpan(text: 'If you skip a day, '),
                      TextSpan(
                          text: 'nothing happens',
                          style: TextStyle(color: AppColors.secondary)),
                      TextSpan(text: '.'),
                    ],
                    subtitle: 'Silence never counts against you.',
                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card blanco que agrupa las filas del ajuste (lista agrupada estilo iOS).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF7E7EC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9A0AE).withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

/// Filete sangrado hasta donde empieza el texto, como iOS.
class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: 76, right: 20),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFF7E7EC)),
      );
}

/// Fila del bloque: icono en cápsula CIRCULAR tintada, título + subtítulo, y a
/// la derecha el control (interruptor o píldora de hora).
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  // Esquinas redondeadas, no círculo: mismo lenguaje que el
                  // resto de iconos dentro de card.
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
