import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../onboarding/presentation/providers/onboarding_controller.dart';
import '../providers/auth_controller.dart';

/// Pantalla inicial. Restaura la sesión (si la hay); si queda autenticada,
/// consulta el estado de onboarding. El router redirige según [AuthStatus] +
/// [OnboardingStatus] resultantes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame: no se debe mutar un provider durante el build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  /// Restaura la sesión y, si sigue viva, resuelve el estado de onboarding para
  /// que el router pueda decidir entre onboarding y home.
  Future<void> _boot() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
    if (!mounted) return;
    final isAuthenticated =
        ref.read(authControllerProvider).status == AuthStatus.authenticated;
    if (isAuthenticated) {
      await ref.read(onboardingStatusProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Aura+', style: textTheme.displaySmall),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
