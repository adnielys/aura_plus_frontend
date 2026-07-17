import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aura_plus/features/onboarding/domain/entities/onboarding_data.dart';
import 'package:aura_plus/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:aura_plus/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:aura_plus/shared/domain/enums.dart';
import 'package:aura_plus/shared/domain/user_profile.dart';

/// Repositorio falso: captura lo enviado y no toca la red.
class _FakeOnboardingRepository implements OnboardingRepository {
  OnboardingData? received;
  bool restarted = false;

  @override
  Future<bool> isCompleted() async => false;

  @override
  Future<void> restart() async => restarted = true;

  @override
  Future<UserProfile> complete(OnboardingData data) async {
    received = data;
    return const UserProfile(
      id: 'u1',
      name: 'Lisi',
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
  group('enums · valores del contrato (reconciliación #7)', () {
    test('coinciden con el snake_case del openapi', () {
      expect(EmotionalState.scattered.wireValue, 'scattered');
      expect(TimeSlot.short.wireValue, 'short');
      expect(PreferredMoment.night.wireValue, 'night');
      expect(MainPain.family.wireValue, 'family');
      expect(ChildAge.small.wireValue, 'small');
      // El caso que más divergía de `.name`:
      expect(PreferredMoment.earlyMorning.wireValue, 'early_morning');
    });
  });

  group('OnboardingController', () {
    late _FakeOnboardingRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeOnboardingRepository();
      container = ProviderContainer(
        overrides: [onboardingRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
    });

    test('la frase es progresiva: nombre y sentimiento obligan, edad/peques no',
        () {
      final controller = container.read(onboardingControllerProvider.notifier);

      // Paso 0 (nombre): requerido.
      expect(container.read(onboardingControllerProvider).canContinue, isFalse);
      controller.setName('Lisi');
      expect(container.read(onboardingControllerProvider).canContinue, isTrue);

      // Paso 1 (edad) y paso 2 (peques): saltarlos siempre está permitido.
      controller.next();
      expect(container.read(onboardingControllerProvider).stepIndex, 1);
      expect(container.read(onboardingControllerProvider).canContinue, isTrue);
      controller.next();
      expect(container.read(onboardingControllerProvider).stepIndex, 2);
      expect(container.read(onboardingControllerProvider).canContinue, isTrue);

      // Paso 3 (sentimiento): requerido.
      controller.next();
      expect(container.read(onboardingControllerProvider).stepIndex, 3);
      expect(container.read(onboardingControllerProvider).canContinue, isFalse);
      controller.toggleFeeling(Feeling.exhausted);
      expect(container.read(onboardingControllerProvider).canContinue, isTrue);

      // Paso 4 (lo que más pesa): pide respuesta.
      controller.next();
      expect(container.read(onboardingControllerProvider).stepIndex, 4);
      expect(container.read(onboardingControllerProvider).canContinue, isFalse);
    });

    test('submit envía los datos (incluida edad opcional) y marca completo',
        () async {
      final controller = container.read(onboardingControllerProvider.notifier)
        ..setName('  Lisi  ')
        ..setAge(34)
        ..toggleFeeling(Feeling.exhausted)..toggleFeeling(Feeling.guilty)
        ..setChildren(count: 2, ages: [ChildAge.small])
        ..setMainPain(MainPain.family)
        ..setTimeSlot(TimeSlot.short)
        ..setMoment(PreferredMoment.night);

      await controller.submit();

      expect(repo.received, isNotNull);
      expect(repo.received!.name, 'Lisi'); // recortado
      expect(repo.received!.age, 34);
      expect(repo.received!.feelings, [Feeling.exhausted, Feeling.guilty]);
      expect(repo.received!.dailyTimeSlot, TimeSlot.short);
      expect(repo.received!.preferredMoment, PreferredMoment.night);
      expect(repo.received!.childrenAges, [ChildAge.small]);
      // Éxito: se muestra el contrato emocional, pero el onboarding NO se marca
      // completo hasta que la usuaria pulsa "Entrar a mi espacio" (SPEC V2 §3.2).
      expect(container.read(onboardingControllerProvider).completed, isTrue);
      expect(
        container.read(onboardingStatusProvider),
        isNot(OnboardingStatus.complete),
      );

      container.read(onboardingControllerProvider.notifier).enterSpace();
      expect(
        container.read(onboardingStatusProvider),
        OnboardingStatus.complete,
      );
    });

    test('submit sin edad: el campo viaja nulo (saltarla está permitido)',
        () async {
      final controller = container.read(onboardingControllerProvider.notifier)
        ..setName('Lisi')
        ..toggleFeeling(Feeling.calm)
        ..setTimeSlot(TimeSlot.short)
        ..setMoment(PreferredMoment.night);

      await controller.submit();

      expect(repo.received, isNotNull);
      expect(repo.received!.age, isNull);
    });
  });
}

