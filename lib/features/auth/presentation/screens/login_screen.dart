import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_controller.dart';

/// Bienvenida + inicio de sesión (maquetado `aura_preview` · pantalla
/// "welcome"): hero a sangre completa, título serif y CTA degradado. Valida en
/// cliente (correo + contraseña ≥8) y delega en el [AuthController]; el router
/// redirige al autenticar.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 14, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.entryBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.entryBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.entryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.error, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final serif = Theme.of(context).textTheme.displaySmall!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Hero a sangre completa (el maquetado lo lleva hasta los bordes).
          Expanded(
            flex: 5,
            child: SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/images/onboarding/welcome.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.16), // object-position 42%
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tagline (mezcla aprobada): la nota de Crecimiento sobre
                    // la base de Protección, en GFS Didot espaciada.
                    const Text(
                      'STRONGER EVERY DAY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTypography.didot,
                        fontSize: 11,
                        letterSpacing: 2.4,
                        color: Color(0xFFB07A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to\nAURA PLUS',
                      textAlign: TextAlign.center,
                      style: serif.copyWith(
                        color: AppColors.entryAccent,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '"A gentle wellness space for women to pause, '
                      'reconnect, and feel calmer and lighter every day."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.entryMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: _decoration('Email'),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _decoration('Password'),
                      validator: (value) => (value == null || value.length < 8)
                          ? 'At least 8 characters'
                          : null,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // CTA del maquetado: pill degradado con destello.
                    SizedBox(
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.entryAccent, AppColors.entryAccentDark],
                          ),
                          borderRadius: BorderRadius.circular(29),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.entryAccent
                                  .withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(29),
                            onTap: state.isSubmitting ? null : _submit,
                            child: Center(
                              child: state.isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign in   ✦',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
