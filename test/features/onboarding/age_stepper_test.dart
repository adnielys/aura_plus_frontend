import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:aura_plus/features/onboarding/presentation/screens/onboarding_screen.dart';

/// Tests del sheet de la edad: además de los ±, el número se TECLEA. Llegar a
/// 42 desde 25 a toques es carga mental, justo lo que la app promete quitar.
void main() {
  /// Monta el onboarding en el paso de la edad (índice 1), que abre su sheet
  /// solo (postFrameCallback del maquetado).
  Future<ProviderContainer> pumpAgeSheet(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    container.read(onboardingControllerProvider.notifier).goToStep(1);
    await tester.pumpAndSettle();
    expect(find.text('How old are you?'), findsOneWidget);
    return container;
  }

  int? ageOf(ProviderContainer container) =>
      container.read(onboardingControllerProvider).age;

  group('sheet de la edad · el número se teclea', () {
    testWidgets('sin tocar nada la edad sigue vacía (el 25 es solo un hint)',
        (tester) async {
      final container = await pumpAgeSheet(tester);
      expect(ageOf(container), isNull);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(
        field.controller!.text,
        isEmpty,
        reason: 'el 25 se pinta de hint; nadie ha respondido todavía',
      );
    });

    testWidgets('teclear 42 deja la edad en 42, sin pasar por los ±',
        (tester) async {
      final container = await pumpAgeSheet(tester);

      await tester.enterText(find.byType(TextField), '42');
      await tester.pumpAndSettle();

      expect(ageOf(container), 42);
    });

    testWidgets('un dígito a medias no se confirma: 1 no se vuelve 16',
        (tester) async {
      final container = await pumpAgeSheet(tester);

      await tester.enterText(find.byType(TextField), '1');
      await tester.pumpAndSettle();
      expect(ageOf(container), isNull, reason: 'todavía está escribiendo 18');

      await tester.enterText(find.byType(TextField), '18');
      await tester.pumpAndSettle();
      expect(ageOf(container), 18);
    });

    testWidgets('fuera de rango se acerca al borde al salir del campo, '
        'nunca se descarta', (tester) async {
      final container = await pumpAgeSheet(tester);

      await tester.enterText(find.byType(TextField), '5');
      await tester.pumpAndSettle();
      expect(ageOf(container), isNull);

      // Salir del campo (tocar el "+" es tocar fuera) ordena lo tecleado.
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      expect(ageOf(container), isNotNull);
      expect(ageOf(container), greaterThanOrEqualTo(16));
    });

    testWidgets('el campo sigue a los ±: son el mismo número', (tester) async {
      final container = await pumpAgeSheet(tester);

      await tester.enterText(find.byType(TextField), '30');
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();

      expect(ageOf(container), 31);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '31');
    });

    testWidgets('no se puede teclear más de dos dígitos ni letras',
        (tester) async {
      final container = await pumpAgeSheet(tester);

      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '12', reason: 'el tope son 2 dígitos');
      expect(
        ageOf(container),
        isNull,
        reason: '12 aún no es una respuesta: se ordena al salir del campo',
      );
    });
  });
}
