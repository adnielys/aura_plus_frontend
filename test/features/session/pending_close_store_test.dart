import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_plus/features/session/data/pending_close_store.dart';
import 'package:aura_plus/shared/domain/enums.dart';

/// Cola offline del cierre: el registro jamás se pierde por la red, pero un
/// cierre pendiente solo vale SU día (descartar viejo = silencio sin culpa).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('guardar y recargar conserva resultados, reflexión y fecha', () async {
    final store = PendingCloseStore();
    await store.save(
      PendingClose(
        date: DateTime(2026, 7, 30),
        habit1Result: HabitResult.done,
        habit2Result: HabitResult.partial,
        habit3Result: HabitResult.notPossible,
        reflection: 'hoy pude',
      ),
    );
    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.date, DateTime(2026, 7, 30));
    expect(loaded.habit1Result, HabitResult.done);
    expect(loaded.habit2Result, HabitResult.partial);
    expect(loaded.habit3Result, HabitResult.notPossible);
    expect(loaded.reflection, 'hoy pude');
  });

  test('los opcionales ausentes vuelven como null', () async {
    final store = PendingCloseStore();
    await store.save(
      PendingClose(date: DateTime(2026, 7, 30), habit1Result: HabitResult.done),
    );
    final loaded = await store.load();
    expect(loaded!.habit2Result, isNull);
    expect(loaded.habit3Result, isNull);
    expect(loaded.reflection, isNull);
  });

  test('clear deja la cola vacía', () async {
    final store = PendingCloseStore();
    await store.save(
      PendingClose(date: DateTime(2026, 7, 30), habit1Result: HabitResult.done),
    );
    await store.clear();
    expect(await store.load(), isNull);
  });

  test('dato corrupto -> null y se limpia solo (mejor silencio que crash)',
      () async {
    SharedPreferences.setMockInitialValues({
      'flutter.pending_day_close_v1': ['no-es-fecha', 'zzz', '', '', ''],
    });
    final store = PendingCloseStore();
    expect(await store.load(), isNull);
    expect(await store.load(), isNull); // idempotente tras la limpieza
  });

  group('isStale — un cierre pendiente solo vale su día', () {
    final pending = PendingClose(
      date: DateTime(2026, 7, 30),
      habit1Result: HabitResult.done,
    );

    test('el mismo día (a cualquier hora) NO está viejo', () {
      expect(pending.isStale(DateTime(2026, 7, 30, 23, 59)), isFalse);
    });

    test('al día siguiente se descarta', () {
      expect(pending.isStale(DateTime(2026, 7, 31, 0, 1)), isTrue);
    });

    test('otro mes u otro año también', () {
      expect(pending.isStale(DateTime(2026, 8, 30)), isTrue);
      expect(pending.isStale(DateTime(2027, 7, 30)), isTrue);
    });
  });
}
