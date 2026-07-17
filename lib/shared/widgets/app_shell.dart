import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  static const _tabs = [
    (route: AppRoutes.home, icon: Icons.home_outlined, label: 'Inicio'),
    (
      route: AppRoutes.constellation,
      icon: Icons.auto_awesome_outlined,
      label: 'Constelación',
    ),
    (route: AppRoutes.cycle, icon: Icons.nightlight_outlined, label: 'Ciclo'),
    (route: AppRoutes.profile, icon: Icons.person_outline, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    Widget item(({String route, IconData icon, String label}) tab) {
      final active = location == tab.route;
      final color = active ? AppColors.primary : AppColors.textSecondary;
      return Expanded(
        child: InkWell(
          onTap: () => context.go(tab.route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 22, color: color),
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
                          child: const Icon(Icons.auto_awesome,
                              size: 22, color: Colors.white),
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
