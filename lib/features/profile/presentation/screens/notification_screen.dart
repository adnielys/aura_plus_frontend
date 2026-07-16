import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
          const SnackBar(content: Text('No pudimos guardar el cambio.')),
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(notificationSettingsProvider),
            child: const Text('Reintentar'),
          ),
        ),
        data: (value) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
          children: [
            const Text('DAILY NOTIFICATION', style: AppTypography.sectionLabel),
            const SizedBox(height: 4),
            const Text(
              'One message a day, at this moment. Nothing more.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: value.isEnabled,
                    onChanged:
                        _saving ? null : (on) => _update(isEnabled: on),
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'Daily message',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      value.isEnabled ? 'On · once a day' : 'Off',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.surfaceTint),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: value.isEnabled && !_saving,
                    onTap: () => _pickTime(value.preferredTime),
                    title: const Text(
                      'Delivery time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Tap to change',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE3EC),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        value.preferredTime,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If you skip a day, nothing happens. Silence never counts '
              'against you.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
