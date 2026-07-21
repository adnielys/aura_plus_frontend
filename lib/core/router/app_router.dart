import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../notifications/local_daily_notifications.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/care/presentation/providers/care_providers.dart';
import '../../features/care/presentation/screens/care_consent_screen.dart';
import '../../features/care/presentation/screens/care_request_screen.dart';
import '../../features/care/presentation/screens/care_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/check_in/presentation/screens/check_in_screen.dart';
import '../../features/check_in/presentation/screens/cycle_screen.dart';
import '../../features/check_in/presentation/screens/home_screen.dart';
import '../../features/check_in/presentation/screens/reco_screen.dart';
import '../../features/constellation/presentation/providers/cycle_closing_provider.dart';
import '../../features/constellation/presentation/screens/constellation_screen.dart';
import '../../features/constellation/presentation/screens/cycle_close_screen.dart';
import '../../features/constellation/presentation/screens/galaxy_screen.dart';
import '../../features/check_in/presentation/providers/daily_flow_controller.dart';
import '../../features/constellation/presentation/providers/constellation_provider.dart';
import '../../features/onboarding/presentation/providers/onboarding_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/providers/history_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import '../../features/profile/presentation/screens/area_gestures_screen.dart';
import '../../features/profile/presentation/screens/areas_screen.dart';
import '../../features/profile/presentation/screens/habit_create_screen.dart';
import '../../features/profile/presentation/screens/habits_catalog_screen.dart';
import '../../features/profile/presentation/screens/history_day_screen.dart';
import '../../features/profile/presentation/screens/history_screen.dart';
import '../../features/profile/presentation/screens/notification_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/session/presentation/providers/session_controller.dart';
import '../../features/session/presentation/providers/session_draft_provider.dart';
import '../../features/session/presentation/screens/celebrate_screen.dart';
import '../../shared/domain/enums.dart';
import '../../shared/widgets/app_shell.dart';

/// Rutas de la app como constantes (sin strings sueltos).
abstract final class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';

  // Tabs dentro del shell (barra inferior del maquetado).
  static const String home = '/home';
  static const String constellation = '/constellation';
  static const String galaxy = '/galaxy';
  static const String cycle = '/cycle';
  static const String profile = '/profile';
  static const String habits = '/habits';
  static const String habitCreate = '/habits/create';
  static const String areas = '/areas';
  static const String areaGestures = '/areas/gestures';
  static const String history = '/history';
  static const String historyDay = '/history/day';
  static const String notification = '/notification';
  static const String care = '/care';
  static const String careConsent = '/care/consent';
  static const String careRequest = '/care/request';

  // Pantallas a pantalla completa (sin barra).
  static const String checkIn = '/check-in';
  static const String checkInResult = '/check-in/result';
  static const String dayClose = '/day-close';
  static const String cycleClose = '/cycle-close';
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
        // La diaria LOCAL de una sesión cerrada no debe sonar.
        cancelDailyNotifications();
      }
      // En CUALQUIER cambio de sesión (salir o entrar) se vacía todo lo
      // user-scoped: otra usuaria jamás debe ver datos cacheados de la
      // sesión anterior. Invalidar también al ENTRAR cubre la carrera del
      // logout (un refetch disparado con los tokens viejos aún válidos).
      if (next != AuthStatus.unknown) {
        ref.invalidate(profileProvider);
        ref.invalidate(notificationSettingsProvider);
        ref.invalidate(historyProvider);
        ref.invalidate(dailyFlowProvider);
        ref.invalidate(sessionControllerProvider);
        ref.invalidate(todaySessionProvider);
        ref.invalidate(sessionDraftProvider);
        ref.invalidate(currentConstellationProvider);
        ref.invalidate(allConstellationsProvider);
        ref.invalidate(cycleClosingProvider);
        ref.invalidate(cycleClosePostponedProvider);
        ref.invalidate(careCurrentReferralProvider);
        ref.invalidate(careDirectoryProvider);
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
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      // Flujo del día a pantalla completa (sin barra inferior).
      GoRoute(
        path: AppRoutes.checkIn,
        builder: (_, _) => const CheckInScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkInResult,
        builder: (_, _) => const RecoScreen(),
      ),
      GoRoute(
        path: AppRoutes.dayClose,
        builder: (_, _) => const CelebrateScreen(),
      ),
      GoRoute(
        path: AppRoutes.cycleClose,
        builder: (_, state) =>
            CycleCloseScreen(closing: state.extra! as CycleClosing),
      ),
      // Tabs bajo el shell con la barra del maquetado.
      ShellRoute(
        builder: (_, _, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.constellation,
            builder: (_, _) => const ConstellationScreen(),
          ),
          GoRoute(
            path: AppRoutes.galaxy,
            builder: (_, _) => const GalaxyScreen(),
          ),
          GoRoute(
            path: AppRoutes.cycle,
            builder: (_, _) => const CycleScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, _) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.habits,
            builder: (_, state) =>
                HabitsCatalogScreen(initialArea: state.extra as HabitArea?),
          ),
          GoRoute(
            path: AppRoutes.habitCreate,
            builder: (_, state) =>
                HabitCreateScreen(args: state.extra as HabitCreateArgs?),
          ),
          GoRoute(
            path: AppRoutes.areas,
            builder: (_, _) => const AreasScreen(),
          ),
          GoRoute(
            path: AppRoutes.areaGestures,
            builder: (_, state) =>
                AreaGesturesScreen(area: state.extra! as HabitArea),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (_, _) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.historyDay,
            builder: (_, state) =>
                HistoryDayScreen(date: state.extra! as DateTime),
          ),
          GoRoute(
            path: AppRoutes.notification,
            builder: (_, _) => const NotificationScreen(),
          ),
          GoRoute(
            path: AppRoutes.care,
            builder: (_, _) => const CareScreen(),
          ),
          GoRoute(
            path: AppRoutes.careConsent,
            builder: (_, state) => CareConsentScreen(
                provider: state.extra! as CareProviderInfo),
          ),
          GoRoute(
            path: AppRoutes.careRequest,
            builder: (_, _) => const CareRequestScreen(),
          ),
        ],
      ),
    ],
    redirect: (_, state) {
      final location = state.matchedLocation;

      return switch (authStatus.value) {
        AuthStatus.unknown =>
          location == AppRoutes.splash ? null : AppRoutes.splash,
        AuthStatus.unauthenticated =>
          (location == AppRoutes.login || location == AppRoutes.register)
              ? null
              : AppRoutes.login,
        // Autenticada: el destino depende del onboarding.
        AuthStatus.authenticated => switch (onboardingStatus.value) {
            // Aún consultando el estado: quedarse en el splash.
            OnboardingStatus.unknown =>
              location == AppRoutes.splash ? null : AppRoutes.splash,
            OnboardingStatus.incomplete =>
              location == AppRoutes.onboarding ? null : AppRoutes.onboarding,
            OnboardingStatus.complete => (location == AppRoutes.splash ||
                    location == AppRoutes.login ||
                    location == AppRoutes.register ||
                    location == AppRoutes.onboarding)
                ? AppRoutes.home
                : null,
          },
      };
    },
  );
});
