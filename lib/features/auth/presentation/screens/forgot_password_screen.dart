import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Pedir el enlace de recuperación (mockup R2). Anti-enumeración: el estado
/// "enviado" es idéntico exista o no la cuenta — este formulario jamás
/// confirma quién está en Aura. El reset ocurre en la web (email).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@') || _sending) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(dioProvider)
          .post<Object?>('/auth/forgot-password', data: {'email': email});
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      // Sin red: se queda en el formulario; puede reintentar cuando vuelva.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 22,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Let's get you back in.", style: serif),
              const SizedBox(height: 8),
              const Text(
                "Tell me your email and I'll send you a link to set a new "
                'password.',
                style: TextStyle(
                    fontSize: 13, height: 1.55, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                enabled: !_sent,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (!_sent)
                SizedBox(
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF8E2C8E)]),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: _sending ? null : _send,
                        child: Center(
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Send me the link  ✦',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'If that email is with us, a link is on its way. '
                    'Check your inbox — it lasts one hour.',
                    style: TextStyle(
                      fontFamily: AppTypography.serif,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF4A4253),
                    ),
                  ),
                ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text(
                    '← Back to sign in',
                    style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
