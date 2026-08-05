import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/core/theme/app_colors.dart';
import 'package:aura_plus/core/theme/app_typography.dart';
import 'package:aura_plus/shared/widgets/aura_dialog.dart';

/// El diálogo de confirmación es una sola pieza para toda la app. Lo que se
/// protege aquí es lo que se rompía al escribirlo a mano en cada pantalla: el
/// tono (serif cursiva, salida neutra) y que cerrarlo por fuera nunca confirme.
void main() {
  /// Monta un botón que abre el diálogo y guarda lo que devuelve.
  Future<List<bool?>> pumpDialog(
    WidgetTester tester, {
    Color? accent,
  }) async {
    final results = <bool?>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(await showAuraConfirm(
                context,
                title: 'Sign out?',
                message: 'Your space stays just as you left it.',
                cancelLabel: 'Stay',
                confirmLabel: 'Sign out',
                accent: accent ?? AppColors.primary,
              ));
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return results;
  }

  group('showAuraConfirm', () {
    testWidgets('la acción devuelve true y la salida neutra false',
        (tester) async {
      final results = await pumpDialog(tester);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(results, [true]);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();
      expect(results, [true, false]);
    });

    testWidgets('cerrarlo por fuera cuenta como NO: un roce no confirma nada',
        (tester) async {
      final results = await pumpDialog(tester);

      // Toque en el velo, fuera de la tarjeta.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(results, [false], reason: 'jamás null, jamás true');
    });

    testWidgets('el título lleva la voz de Aura: serif en cursiva',
        (tester) async {
      await pumpDialog(tester);

      final title = tester.widget<Text>(find.text('Sign out?'));
      expect(title.style!.fontFamily, AppTypography.serif);
      expect(title.style!.fontStyle, FontStyle.italic);
    });

    testWidgets('la salida neutra nunca compite con la acción', (tester) async {
      await pumpDialog(tester);

      final cancel = tester.widget<Text>(find.text('Stay'));
      final confirm = tester.widget<Text>(find.text('Sign out'));
      expect(cancel.style!.color, AppColors.textSecondary);
      expect(cancel.style!.fontWeight, FontWeight.w400);
      expect(confirm.style!.fontWeight, FontWeight.w700);
    });

    testWidgets('cada mundo pone su acento: care va en verde', (tester) async {
      await pumpDialog(tester, accent: AppColors.careAccent);

      final confirm = tester.widget<Text>(find.text('Sign out'));
      expect(confirm.style!.color, AppColors.careAccent);
    });
  });
}
