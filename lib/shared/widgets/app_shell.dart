import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

/// Shell con la barra inferior del maquetado: Inicio · Constelación · [FAB
/// check-in] · Ciclo · Perfil. El FAB estrella lleva al check-in a pantalla
/// completa (fuera del shell).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // El día de la usuaria se calcula en SU timezone: se sincroniza con el
    // servidor una vez por arranque, ya autenticada (fire-and-forget).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => syncDeviceTimezone(ref),
    );
  }

  Widget get child => widget.child;

  // Iconos estilo iOS (Cupertino): contorno en reposo, RELLENO al estar
  // activo — la convención de la barra de pestañas de iOS.
  static const _tabs = [
    (
      route: AppRoutes.home,
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      asset: null,
      label: 'Today',
    ),
    (
      route: AppRoutes.constellation,
      icon: CupertinoIcons.sparkles,
      activeIcon: CupertinoIcons.sparkles,
      asset: 'assets/images/nav_constellation.svg',
      label: 'Constellation',
    ),
    (
      route: AppRoutes.support,
      icon: CupertinoIcons.chat_bubble_2,
      activeIcon: CupertinoIcons.chat_bubble_2_fill,
      asset: null,
      label: 'Support',
    ),
    (
      route: AppRoutes.profile,
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      asset: null,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    Widget item(
        ({
          String route,
          IconData icon,
          IconData activeIcon,
          String? asset,
          String label
        }) tab) {
      final active = location == tab.route;
      final color = active ? AppColors.primary : AppColors.textSecondary;
      final iconWidget = tab.asset != null
          ? SvgPicture.asset(
              tab.asset!,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          : Icon(active ? tab.activeIcon : tab.icon, size: 22, color: color);
      return Expanded(
        child: InkWell(
          onTap: () => context.go(tab.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(height: 2),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Color(0xFFEDE7F2), width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              item(_tabs[0]),
              item(_tabs[1]),
              // FAB central: check-in (la estrella de Aura).
              Expanded(
                child: InkWell(
                  onTap: () => context.go(AppRoutes.checkIn),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/aura_star.svg',
                              width: 22,
                              height: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'Check-in',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              item(_tabs[2]),
              item(_tabs[3]),
            ],
          ),
        ),
      ),
    );
  }
}
