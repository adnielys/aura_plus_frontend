import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/features/onboarding/domain/entities/onboarding_data.dart';
import 'package:aura_plus/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:aura_plus/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:aura_plus/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:aura_plus/features/onboarding/presentation/widgets/onboarding_card.dart';
import 'package:aura_plus/shared/domain/enums.dart';
import 'package:aura_plus/shared/domain/user_profile.dart';

/// Tests del onboarding partido en dos cards. Lo que se protege: que el
/// recorrido se lea en dos tramos, que la corrección devuelva a las cards sin
/// repetir el flujo, y sobre todo que el CONTRATO no se haya movido — la
/// reestructura era de UI, y el día que deje de serlo tiene que cantar aquí.
class _FakeRepo implements OnboardingRepository {
  final sent = <OnboardingData>[];

  /// Deja el POST colgado a voluntad. Sin esto el falso responde en el mismo
  /// microtask y el cerrojo de reentrada nunca llega a probarse: en la app
  /// real hay red por medio, que es justo cuando cabe el segundo toque.
  Completer<void>? gate;

  @override
  Future<bool> isCompleted() async => false;

  @override
  Future<void> restart() async {}

  @override
  Future<UserProfile> complete(OnboardingData data) async {
    sent.add(data);
    if (gate != null) await gate!.future;
    return const UserProfile(
      id: 'u1',
      name: 'Yuko',
      childrenCount: 2,
      childrenAges: [ChildAge.small],
      mainPain: MainPain.family,
      dailyTimeSlot: TimeSlot.short,
      preferredMoment: PreferredMoment.night,
      onboardingCompleted: true,
    );
  }
}

void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  OnboardingController ctrl() =>
      container.read(onboardingControllerProvider.notifier);
  OnboardingState state() => container.read(onboardingControllerProvider);

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  void answerBlock1() {
    ctrl()
      ..setName('Yuko')
      ..setAge(28)
      ..setChildren(count: 2, ages: const [ChildAge.small])
      ..toggleFeeling(Feeling.exhausted);
  }

  void answerBlock2() {
    ctrl()
      ..setMainPain(MainPain.family)
      ..setTimeSlot(TimeSlot.short)
      ..setMoment(PreferredMoment.night);
  }

  /// El paso 4 abre el modal de sentimientos SOLO, así que tapa el botón del
  /// bloque hasta que se cierra. Es el comportamiento de la app, no un
  /// artefacto del test.
  Future<void> closeFeelingsModal(WidgetTester tester) async {
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }

  /// Deja las dos cards en pantalla con todo respondido.
  Future<void> gotoCards(WidgetTester tester) async {
    answerBlock1();
    ctrl().goToStep(3);
    ctrl().closeBlock();
    answerBlock2();
    ctrl().goToStep(6);
    ctrl().closeBlock();
    await pump(tester);
  }

  group('bloque 1', () {
    testWidgets('cuenta sus propios pasos, no los siete', (tester) async {
      await pump(tester);
      expect(find.text('Block 1 · Step 1 of 4'), findsOneWidget);
      expect(find.textContaining('of 7'), findsNothing);
    });

    testWidgets('su último paso no dice "continuar": cierra la card',
        (tester) async {
      answerBlock1();
      ctrl().goToStep(3);
      await pump(tester);

      expect(find.text('Block 1 · Step 4 of 4'), findsOneWidget);
      expect(find.text('Close this card'), findsOneWidget);
      expect(find.text('Start with Aura+'), findsNothing,
          reason: 'enviar ya no ocurre aquí');
    });
  });

  group('el pliegue lleva al bloque 2', () {
    testWidgets('con su contador propio, empezando de nuevo en 1',
        (tester) async {
      answerBlock1();
      ctrl().goToStep(3);
      await pump(tester);
      await closeFeelingsModal(tester);

      await tester.tap(find.text('Close this card'));
      await tester.pumpAndSettle();

      expect(state().view, OnboardingView.block2);
      expect(find.text('Block 2 · Step 1 of 3'), findsOneWidget);
      expect(find.text('See both cards'), findsNothing,
          reason: 'aún queda camino dentro del bloque');
    });

    testWidgets('el modal de sentimientos no se cuela detrás del bloque 2',
        (tester) async {
      answerBlock1();
      ctrl().goToStep(3);
      await pump(tester);
      await closeFeelingsModal(tester);

      await tester.tap(find.text('Close this card'));
      await tester.pumpAndSettle();

      // El paso 4 abre su modal en initState. Si el pliegue recrea el
      // subárbol, vuelve a dispararse y —al ser una ruta— sobrevive al cambio
      // de vista: te quedabas con la rejilla de sentimientos de fondo y el
      // sheet del día encima.
      expect(find.text('How do you feel today?'), findsNothing);
      expect(find.text('choose all that apply'), findsNothing);
      // Detrás del sheet del día tiene que estar SU frase.
      expect(find.textContaining('the hardest part is'), findsWidgets);
    });

    testWidgets('primero aterriza la card con su frase, después el sheet',
        (tester) async {
      answerBlock1();
      ctrl().goToStep(3);
      await pump(tester);
      await closeFeelingsModal(tester);

      await tester.tap(find.text('Close this card'));
      await tester.pump(); // arranca el pliegue
      await tester.pump(const Duration(milliseconds: 760)); // termina
      await tester.pump(const Duration(milliseconds: 200)); // la card sube

      // Lo primero que se ve del bloque nuevo es de qué va a ir la pregunta.
      expect(find.textContaining('the hardest part is'), findsWidgets);
      expect(find.text('What weighs on you most?'), findsNothing,
          reason: 'abrirlo aquí taparía justo lo que se acaba de presentar');

      await tester.pumpAndSettle();
      expect(find.text('What weighs on you most?'), findsOneWidget);
    });

    testWidgets('el sheet del día se abre UNA vez, no dos', (tester) async {
      answerBlock1();
      ctrl().goToStep(3);
      await pump(tester);
      await closeFeelingsModal(tester);

      await tester.tap(find.text('Close this card'));
      await tester.pumpAndSettle();

      // La pantalla del bloque 1 sigue viva mientras se desliza fuera. Si en
      // esos 420 ms se pusiera a leer el paso nuevo, pintaría el bloque 2 a la
      // vez que la que entra: dos pasos del día montados, dos sheets abiertos,
      // y al cerrar uno aparecía el otro.
      expect(find.text('What weighs on you most?'), findsOneWidget);
    });
  });

  group('las dos cards', () {
    testWidgets('se pintan las dos, con lo que ella contó', (tester) async {
      await gotoCards(tester);

      expect(find.byType(OnboardingCard), findsNWidgets(2));
      expect(find.text('THIS IS WHAT YOU TOLD ME'), findsOneWidget);
      // El nombre y el dato del día viven cada uno en su card.
      expect(find.textContaining('Yuko'), findsWidgets);
      expect(find.textContaining('my family and home'), findsWidgets);
    });

    testWidgets('tocar la card activa la abre a corregir', (tester) async {
      await gotoCards(tester);

      await tester.tap(find.byType(OnboardingCard).first);
      await tester.pumpAndSettle();

      expect(state().view, OnboardingView.editing);
      expect(find.text('Card 1 of 2'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('corregir el nombre dentro de la card', () {
    testWidgets('el botón cierra el campo, no la card', (tester) async {
      await gotoCards(tester);
      ctrl().openCard(1);
      await tester.pumpAndSettle();

      // Tocar el nombre lo convierte en campo: el botón cambia de oficio.
      await tester.tap(find.text('My name is'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Save'), findsNothing);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Sigue en la card, con el campo ya cerrado y "Save" de vuelta.
      expect(state().view, OnboardingView.editing,
          reason: 'cerrar el campo no cierra la card');
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('guardar una corrección', () {
    testWidgets('vuelve a las cards y conserva el cambio', (tester) async {
      await gotoCards(tester);
      ctrl().openCard(1);
      await tester.pumpAndSettle();

      // Corregir el nombre sin pasar por el flujo de pasos.
      ctrl().setName('Eloise');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(state().view, OnboardingView.cards);
      expect(state().name, 'Eloise');
      expect(find.byType(OnboardingCard), findsNWidgets(2));
      expect(find.textContaining('Eloise'), findsWidgets);
    });
  });

  group('el envío', () {
    testWidgets('ocurre UNA vez, al pulsar "Start with Aura+", y con el mismo '
        'payload de siempre', (tester) async {
      await gotoCards(tester);

      expect(repo.sent, isEmpty, reason: 'llegar a las cards no envía nada');

      await tester.tap(find.text('Start with Aura+'));
      await tester.pumpAndSettle();

      expect(repo.sent, hasLength(1));
      final data = repo.sent.single;
      expect(data.name, 'Yuko');
      expect(data.age, 28);
      expect(data.feelings, [Feeling.exhausted]);
      expect(data.childrenCount, 2);
      expect(data.childrenAges, [ChildAge.small]);
      expect(data.mainPain, MainPain.family);
      expect(data.dailyTimeSlot, TimeSlot.short);
      expect(data.preferredMoment, PreferredMoment.night);
    });

    testWidgets('mientras el POST vuela no se puede enviar otra vez',
        (tester) async {
      await gotoCards(tester);
      repo.gate = Completer<void>();

      await tester.tap(find.text('Start with Aura+'));
      await tester.pump();

      // Primera defensa: el botón se pone en carga y su texto desaparece, así
      // que ni siquiera hay dónde volver a tocar.
      expect(find.text('Start with Aura+'), findsNothing);
      expect(repo.sent, hasLength(1));

      // Segunda: aunque algo llamara a submit() igualmente, el cerrojo del
      // controller no deja pasar un segundo envío.
      await ctrl().submit();
      expect(repo.sent, hasLength(1));

      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(repo.sent, hasLength(1));
    });

    testWidgets('y después llega el contrato emocional', (tester) async {
      await gotoCards(tester);

      await tester.tap(find.text('Start with Aura+'));
      await tester.pumpAndSettle();

      expect(state().view, OnboardingView.contract);
      expect(find.text('Enter my space'), findsOneWidget);
    });
  });
}
