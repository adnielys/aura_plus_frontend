import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// `auth` es módulo fundacional compartido (como en el backend con CurrentUser):
// otras features pueden leer el estado de sesión sin romper el aislamiento.
import '../../../auth/presentation/providers/auth_controller.dart';

/// Home placeholder tras el login. En el Prompt 3 alojará el check-in y las
/// HabitCard; por ahora solo confirma la sesión y permite cerrarla.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aura+'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sesión iniciada. Aquí vivirá tu día: check-in y hábitos.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
