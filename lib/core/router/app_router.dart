import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/check_in/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Rutas de la app como constantes (sin strings sueltos).
abstract final class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
}

/// Router gobernado por [AuthStatus] + [OnboardingStatus].
///
/// Sendos [ValueNotifier] espejo alimentan `refreshListenable`, de modo que
/// GoRouter reevalúa el `redirect` cuando cambia la sesión o el onboarding. El
/// `redirect` lee esos espejos (no los providers) para mantenerse síncrono.
final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ValueNotifier<AuthStatus>(AuthStatus.unknown);
  final onboardingStatus = ValueNotifier<OnboardingStatus>(OnboardingStatus.unknown);

  ref.listen(
    authControllerProvider.select((state) => state.status),
    (_, next) {
      authStatus.value = next;
      // Al cerrar sesión, el onboarding vuelve a desconocido: el siguiente login
      // (quizá de otra usuaria) debe reconsultar su estado, no heredar el previo.
      if (next == AuthStatus.unauthenticated) {
        ref.read(onboardingStatusProvider.notifier).reset();
      }
    },
    fireImmediately: true,
  );
  ref.listen(
    onboardingStatusProvider,
    (_, next) => onboardingStatus.value = next,
    fireImmediately: true,
  );

  final refresh = Listenable.merge([authStatus, onboardingStatus]);
  ref.onDispose(() {
    authStatus.dispose();
    onboardingStatus.dispose();
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
    ],
    redirect: (_, state) {
      final location = state.matchedLocation;

      return switch (authStatus.value) {
        AuthStatus.unknown =>
          location == AppRoutes.splash ? null : AppRoutes.splash,
        AuthStatus.unauthenticated =>
          location == AppRoutes.login ? null : AppRoutes.login,
        // Autenticada: el destino depende del onboarding.
        AuthStatus.authenticated => switch (onboardingStatus.value) {
            // Aún consultando el estado: quedarse en el splash.
            OnboardingStatus.unknown =>
              location == AppRoutes.splash ? null : AppRoutes.splash,
            OnboardingStatus.incomplete =>
              location == AppRoutes.onboarding ? null : AppRoutes.onboarding,
            OnboardingStatus.complete => (location == AppRoutes.splash ||
                    location == AppRoutes.login ||
                    location == AppRoutes.onboarding)
                ? AppRoutes.home
                : null,
          },
      };
    },
  );
});
