import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:aura_plus/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:aura_plus/features/onboarding/presentation/widgets/pain_reflection.dart';
import 'package:aura_plus/shared/domain/enums.dart';

/// Tests del reflejo emocional (SPEC V2 §3.1/§3.3): el mapa está completo y
/// la línea cambia al cambiar la selección — la primera respuesta de Aura.
void main() {
  group('painReflections (mapa aprobado)', () {
    test('cubre las 5 opciones, sin strings vacíos y sin repetidos', () {
      expect(painReflections.length, MainPain.values.length);
      for (final pain in MainPain.values) {
        expect(painReflections[pain], isNotNull, reason: pain.name);
        expect(painReflections[pain]!.trim(), isNotEmpty, reason: pain.name);
      }
      expect(
        painReflections.values.toSet().length,
        MainPain.values.length,
        reason: 'cada elección merece su propio reflejo',
      );
    });

    test('los textos son los aprobados (jul 2026)', () {
      expect(
        painReflections[MainPain.self],
        'Putting yourself on the list is already a good start.',
      );
      expect(
        painReflections[MainPain.family],
        "Holding a home together is invisible work. Here, it's seen.",
      );
    });
  });

  group('paso 4 · la línea cambia con la selección', () {
    testWidgets('tocar un chip muestra su reflejo; cambiar lo sustituye',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      // Ir directo al paso de "lo que más pesa" (índice 4).
      container.read(onboardingControllerProvider.notifier).goToStep(4);
      await tester.pumpAndSettle();

      // Sin selección: ningún reflejo en pantalla.
      expect(find.text(painReflections[MainPain.work]!), findsNothing);

      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();
      expect(find.text(painReflections[MainPain.work]!), findsOneWidget);

      await tester.tap(find.text('Myself'));
      await tester.pumpAndSettle();
      expect(find.text(painReflections[MainPain.self]!), findsOneWidget);
      expect(find.text(painReflections[MainPain.work]!), findsNothing);
    });
  });
}
