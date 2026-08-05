import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:aura_plus/shared/domain/enums.dart';

/// Tests de la capa de vista del onboarding en dos cards. Lo que se protege
/// aquí es la frontera: `stepIndex` sigue mandando sobre las RESPUESTAS y la
/// vista solo decide qué se ve. Si alguna transición tocara una respuesta, la
/// reestructura habría dejado de ser de UI.
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  OnboardingState get_() => container.read(onboardingControllerProvider);
  OnboardingController ctrl() =>
      container.read(onboardingControllerProvider.notifier);

  /// Deja el bloque 1 respondido y plantado en su último paso.
  void answerBlock1() {
    ctrl()
      ..setName('Yuko')
      ..setAge(28)
      ..setChildren(count: 1, ages: const [ChildAge.baby])
      ..toggleFeeling(Feeling.exhausted)
      ..goToStep(3);
  }

  void answerBlock2() {
    ctrl()
      ..setMainPain(MainPain.work)
      ..setTimeSlot(TimeSlot.short)
      ..setMoment(PreferredMoment.night);
  }

  group('reglas por paso y por bloque', () {
    test('isStepAnswered es la única tabla: canContinue sale de ella', () {
      expect(get_().canContinue, isFalse, reason: 'sin nombre no se avanza');
      ctrl().setName('Yuko');
      expect(get_().canContinue, isTrue);

      // Edad y peques son opcionales: su paso siempre deja pasar.
      expect(get_().isStepAnswered(1), isTrue);
      expect(get_().isStepAnswered(2), isTrue);
      expect(get_().isStepAnswered(3), isFalse, reason: 'sin sentimientos');
    });

    test('un bloque está completo cuando lo están TODOS sus pasos', () {
      expect(get_().isBlockComplete(1), isFalse);
      ctrl().setName('Yuko');
      expect(get_().isBlockComplete(1), isFalse, reason: 'faltan sentimientos');
      ctrl().toggleFeeling(Feeling.lonely);
      expect(get_().isBlockComplete(1), isTrue);

      expect(get_().isBlockComplete(2), isFalse);
      answerBlock2();
      expect(get_().isBlockComplete(2), isTrue);
    });

    test('el contador conoce su bloque: 4 pasos y luego 3', () {
      expect(get_().block, 1);
      expect(get_().stepInBlock, 1);
      expect(get_().stepsInBlock, 4);

      ctrl().goToStep(4);
      expect(get_().block, 2);
      expect(get_().stepInBlock, 1, reason: 'el bloque 2 vuelve a empezar');
      expect(get_().stepsInBlock, 3);

      ctrl().goToStep(6);
      expect(get_().stepInBlock, 3);
    });
  });

  group('next() ya no cruza de bloque', () {
    test('en el último paso del bloque 1 se queda: eso lo cierra closeBlock',
        () {
      answerBlock1();
      expect(get_().isLastStepOfBlock, isTrue);
      ctrl().next();
      expect(get_().stepIndex, 3, reason: 'no salta al bloque 2 por su cuenta');
      expect(get_().view, OnboardingView.block1);
    });

    test('dentro del bloque avanza como siempre', () {
      ctrl().setName('Yuko');
      ctrl().next();
      expect(get_().stepIndex, 1);
    });
  });

  group('el pliegue', () {
    test('startFold marca, closeBlock lleva al bloque 2 por su primer paso',
        () {
      answerBlock1();
      ctrl().startFold();
      expect(get_().folding, isTrue);

      ctrl().closeBlock();
      expect(get_().folding, isFalse);
      expect(get_().view, OnboardingView.block2);
      expect(get_().stepIndex, 4);
    });

    test('plegar NO toca ninguna respuesta', () {
      answerBlock1();
      final before = get_();
      ctrl()
        ..startFold()
        ..closeBlock();
      final after = get_();

      expect(after.name, before.name);
      expect(after.age, before.age);
      expect(after.feelings, before.feelings);
      expect(after.childrenCount, before.childrenCount);
      expect(after.childrenAges, before.childrenAges);
    });

    test('cerrar el bloque 2 lleva a las cards, sin mover el paso', () {
      answerBlock1();
      ctrl().closeBlock();
      answerBlock2();
      ctrl().goToStep(6);

      ctrl().closeBlock();
      expect(get_().view, OnboardingView.cards);
      expect(get_().stepIndex, 6, reason: 'las cards no recorren pasos');
    });
  });

  group('editar una card', () {
    test('abrir y guardar vuelve a las cards en la card editada', () {
      answerBlock1();
      ctrl().closeBlock();
      answerBlock2();
      ctrl().closeBlock();

      ctrl().openCard(2);
      expect(get_().view, OnboardingView.editing);
      expect(get_().editingCard, 2);

      ctrl().saveCard();
      expect(get_().view, OnboardingView.cards);
      expect(get_().editingCard, 2, reason: 'vuelve donde estaba, no al inicio');
    });

    test('con el bloque incompleto, guardar no hace nada', () {
      answerBlock1();
      ctrl().closeBlock();
      ctrl().closeBlock(); // a cards sin responder el bloque 2
      ctrl().openCard(2);

      ctrl().saveCard();
      expect(get_().view, OnboardingView.editing, reason: 'sigue abierta');
    });

    test('una card que no existe se ignora', () {
      ctrl().openCard(3);
      expect(get_().view, OnboardingView.block1);
    });
  });

  group('restart', () {
    test('devuelve la vista al bloque 1, no solo las respuestas', () {
      answerBlock1();
      ctrl().closeBlock();
      answerBlock2();
      ctrl().closeBlock();
      ctrl().openCard(1);

      ctrl().restart();

      expect(get_().view, OnboardingView.block1);
      expect(get_().stepIndex, 0);
      expect(get_().editingCard, 1);
      expect(get_().folding, isFalse);
      expect(get_().name, isEmpty);
      expect(get_().feelings, isEmpty);
    });
  });
}
