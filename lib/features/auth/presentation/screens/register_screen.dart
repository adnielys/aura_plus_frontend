import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/auth_controller.dart';

/// Crear cuenta (zona de entrada, mismo lenguaje visual que el login).
/// `POST /auth/register` devuelve tokens: entra directo y el router la lleva
/// al onboarding.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'YOUR SPACE BEGINS HERE',
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
                    'Create your\naccount',
                    textAlign: TextAlign.center,
                    style: serif.copyWith(
                      color: AppColors.entryAccent,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'A few seconds and your gentle space is ready.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.entryMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    textInputAction: TextInputAction.next,
                    decoration: _decoration('Your name'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Tell us your name'
                            : null,
                  ),
                  const SizedBox(height: 12),
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
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _decoration('Password (8+ characters)'),
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
                  SizedBox(
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.entryAccent,
                            AppColors.entryAccentDark
                          ],
                        ),
                        borderRadius: BorderRadius.circular(29),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.entryAccent.withValues(alpha: 0.35),
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
                                    'Create account   ✦',
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
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: AppColors.entryMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
