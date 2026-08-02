import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/soft_primary_button.dart';

/// Cambiar contraseña con sesión abierta (perfil · SESSION). Exige la actual;
/// el servidor revoca las demás sesiones y devuelve un par nuevo — este
/// dispositivo sigue dentro sin relogin.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _fresh = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _note;

  @override
  void dispose() {
    _current.dispose();
    _fresh.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_fresh.text.length < 8) {
      setState(() => _note = 'Eight characters or more keeps it safe.');
      return;
    }
    if (_fresh.text != _confirm.text) {
      setState(() => _note = "Those two didn't match — one more try.");
      return;
    }
    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      final response = await ref.read(dioProvider).post<Object?>(
        '/auth/change-password',
        data: {
          'current_password': _current.text,
          'new_password': _fresh.text,
        },
      );
      final tokens = unwrapEnvelope(response.data) as Map;
      // El servidor revocó todo y emitió un par nuevo: lo guardamos para que
      // ESTE dispositivo siga dentro (los demás quedaron fuera).
      await ref.read(tokenStorageProvider).saveTokens(
            access: tokens['access_token'] as String,
            refresh: tokens['refresh_token'] as String,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Done — your password is new.')));
      context.go(AppRoutes.profile);
    } on ApiException {
      if (mounted) {
        setState(() => _note = "That current password doesn't match.");
      }
    } catch (_) {
      if (mounted) {
        setState(() => _note = 'No connection right now — try again in a bit.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 24),
          children: [
            Text('A new password.', style: serif),
            const SizedBox(height: 8),
            const Text(
              'For your safety this signs you out on any other device — '
              'this one stays in.',
              style: TextStyle(
                  fontSize: 13, height: 1.55, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _field(_current, 'Current password'),
            const SizedBox(height: 10),
            _field(_fresh, 'New password (8+ characters)'),
            const SizedBox(height: 10),
            _field(_confirm, 'Repeat it, just to be sure'),
            if (_note != null) ...[
              const SizedBox(height: 10),
              Text(
                _note!,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.primary, height: 1.5),
              ),
            ],
            const SizedBox(height: 18),
            SoftPrimaryButton(
              label: 'Save my new password',
              onPressed: _submit,
              isLoading: _busy,
            ),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.profile),
                child: const Text(
                  '← Back',
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

  Widget _field(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
