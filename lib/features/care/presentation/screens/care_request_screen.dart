import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/dates.dart';
import '../providers/care_providers.dart';
import '../widgets/care_widgets.dart';

/// D4 · Mi solicitud: el espacio de la petición en curso.
///
/// Muestra SOLO lo andado (Enviada → En sus manos → Respuesta, sin reloj ni
/// "lleva X días" — GUARD de tono) y la única salida activa es suya:
/// "Retirar mi petición" (withdrawn, sin castigo — el directorio se
/// desbloquea y puede volver a pedir a quien quiera, incluso a ella).
class CareRequestScreen extends ConsumerStatefulWidget {
  const CareRequestScreen({super.key});

  @override
  ConsumerState<CareRequestScreen> createState() => _CareRequestScreenState();
}

class _CareRequestScreenState extends ConsumerState<CareRequestScreen> {
  bool _withdrawing = false;

  Future<void> _withdraw(CareReferral referral, String name) async {
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Retiro tu petición a $name?',
          style: const TextStyle(
            fontFamily: AppTypography.serif,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Podrás elegir a otra persona cuando quieras — '
          'o a ella misma más adelante. Sin prisa.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Dejarla como está',
              style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Retirarla',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.careAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _withdrawing = true);
    try {
      await advanceCareReferral(
        ref,
        referralId: referral.id,
        status: 'withdrawn',
      );
      // El directorio queda libre otra vez; la fila del perfil, en reposo.
      router.go(AppRoutes.care);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo retirar. Inténtalo de nuevo.')),
        );
        setState(() => _withdrawing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final referralAsync = ref.watch(careCurrentReferralProvider);
    final referral = referralAsync.valueOrNull;

    // Si la solicitud dejó de estar pendiente (respondió, se retiró, o no
    // hay), el flujo raíz decide la vista correcta.
    if (referralAsync.hasValue && resolveCareView(referral) != CareView.sent) {
      final router = GoRouter.of(context);
      Future.microtask(() {
        if (mounted) router.go(AppRoutes.care);
      });
    }

    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );
    final fullName = referral?.providerName ?? '';
    final name = fullName.isEmpty ? 'sus manos' : shortProviderName(fullName);

    return Scaffold(
      body: SafeArea(
        child: referral == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.careAccent),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  const CareBackRow(),
                  const SizedBox(height: 6),
                  const Text('TU SOLICITUD', style: AppTypography.sectionLabel),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'En manos de $name, ', style: serif),
                      TextSpan(
                        text: 'sin prisa.',
                        style: serif.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.careBorder),
                    ),
                    child: Column(
                      children: [
                        CareProviderCard(
                          name: fullName.isEmpty ? 'Tu persona de apoyo' : fullName,
                          meta: 'Petición en curso',
                          tier: 'support',
                        ),
                        const SizedBox(height: 12),
                        const _RequestSteps(),
                        const SizedBox(height: 10),
                        Text(
                          _metaLine(referral),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Suele responder en unos días. Yo te aviso aquí — '
                    'tú no tienes que hacer nada, ni estar pendiente.',
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.6,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  CarePrimaryButton(
                    label: 'Volver a mi espacio',
                    crimson: true,
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _withdrawing
                          ? null
                          : () => _withdraw(referral, name),
                      child: Text(
                        _withdrawing ? 'Retirando…' : 'Retirar mi petición',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFA2596F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// "Enviada el 18 de julio · compartiste solo tu nombre" — transparencia
  /// serena: fecha (sin cuenta de días) y qué viajó en la petición.
  String _metaLine(CareReferral referral) {
    final sent = referral.createdAt == null
        ? 'Enviada'
        : 'Enviada el ${spanishDate(referral.createdAt!.toLocal())}';
    final shared = (referral.sharedPayload?['name'] as String?) == null
        ? 'no compartiste tus datos'
        : 'compartiste solo tu nombre';
    return '$sent · $shared';
  }
}

/// Pasos de la solicitud: solo lo andado se enciende; "Respuesta" espera sin
/// reloj.
class _RequestSteps extends StatelessWidget {
  const _RequestSteps();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Enviada', true),
      ('En sus manos', true),
      ('Respuesta', false),
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
