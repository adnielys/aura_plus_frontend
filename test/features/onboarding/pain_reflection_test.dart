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

  group('timeReflections (3/3) y momentReflections (4/4) — aprobados', () {
    test('cubren todas las opciones sin vacíos ni repetidos', () {
      expect(timeReflections.length, TimeSlot.values.length);
      expect(momentReflections.length, PreferredMoment.values.length);
      for (final text in [
        ...timeReflections.values,
        ...momentReflections.values,
        timeReflectionDefault,
        momentReflectionDefault,
      ]) {
        expect(text.trim(), isNotEmpty);
      }
      expect(timeReflections.values.toSet().length, TimeSlot.values.length);
      expect(
        momentReflections.values.toSet().length,
        PreferredMoment.values.length,
      );
    });

    test('5 minutos se valida TAL CUAL — jamás un benchmark de 10', () {
      expect(
        timeReflections[TimeSlot.minimal],
        "Five minutes is not little — it's a door. Aura fits inside it.",
      );
      expect(timeReflections[TimeSlot.minimal], isNot(contains('Ten')));
    });

    test('la promesa 1/día está en las 4 variantes de momento', () {
      for (final text in momentReflections.values) {
        expect(text, contains('One message a day'));
        expect(text, contains('Nothing more.'));
      }
    });
  });

  group('paso 5 · el reflejo de tiempo cambia con la selección', () {
    testWidgets('sin selección el neutro; con 5 min su validación',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      // Los pasos del día viven en el bloque 2, y cada pantalla dibuja solo
      // los suyos: hay que cerrar el bloque 1 para llegar.
      container.read(onboardingControllerProvider.notifier)
        ..closeBlock()
        ..goToStep(5);
      await tester.pumpAndSettle();
      expect(find.text(timeReflectionDefault), findsOneWidget);

      await tester.tap(find.text('Almost none (5 min)'));
      await tester.pumpAndSettle();
      expect(find.text(timeReflections[TimeSlot.minimal]!), findsOneWidget);
      expect(find.text(timeReflectionDefault), findsNothing);
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
      // Ir al paso de "lo que más pesa" (índice 4): es el primero del bloque
      // 2, así que se llega cerrando el bloque 1.
      container.read(onboardingControllerProvider.notifier).closeBlock();
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
