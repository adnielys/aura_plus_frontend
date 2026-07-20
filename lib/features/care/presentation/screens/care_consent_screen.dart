import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/care_providers.dart';
import '../widgets/care_widgets.dart';

/// A3 · Consentir y pedir. ELLA decide qué se comparte antes de enviar nada.
///
/// Con el interruptor encendido se comparte SOLO su nombre y que pidió apoyo
/// (GUARD_CARE_07); apagado, la petición llega igual — anónima. El CTA es
/// honesto: "enviar petición", no "conectar" (la conexión llega con el sí
/// del otro lado).
class CareConsentScreen extends ConsumerStatefulWidget {
  const CareConsentScreen({super.key, required this.provider});

  final CareProviderInfo provider;

  @override
  ConsumerState<CareConsentScreen> createState() => _CareConsentScreenState();
}

class _CareConsentScreenState extends ConsumerState<CareConsentScreen> {
  bool _shareName = true;
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await createCareReferral(
        ref,
        providerId: widget.provider.id,
        shareName: _shareName,
      );
      if (mounted) context.go(AppRoutes.careRequest); // D4: mi solicitud
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Couldn't send it. Try again.")),
        );
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    // Base serif SIN itálica; acento en itálica carmesí (como el mockup A3).
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
          color: AppColors.textPrimary,
        );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => context.go(AppRoutes.care),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new,
                        size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 6),
                    Text('Directory',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            CareProviderCard(
              name: provider.fullName,
              meta: providerMetaLine(provider),
              tier: provider.tier,
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Before asking to connect, ', style: serif),
                TextSpan(
                  text: 'you decide what is shared.',
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
                color: const Color(0xFFFBF8FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ONLY THIS IS SHARED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Switch(
                        value: _shareName,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        onChanged: (value) =>
                            setState(() => _shareName = value),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Your name, and that you asked for support.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔒', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nothing from your journal, your check-ins or your stars. '
                          'Ever.',
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'With the switch off, the request still goes through — '
              'sharing nothing about you.',
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            CarePrimaryButton(
              label: 'Send request to ${shortProviderName(provider.fullName)}',
              busy: _sending,
              onPressed: _send,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.care),
                child: const Text(
                  'Back',
                  style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
