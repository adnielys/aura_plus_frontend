import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/domain/enums.dart';

/// Un cierre del día que NO pudo llegar al servidor (sin red).
///
/// El registro ya es el logro: se guarda tal cual lo marcó ella y se
/// reintenta en silencio. Las estrellas NUNCA se calculan aquí
/// (GUARD_STAR_02: el servidor es la única fuente de verdad).
class PendingClose {
  const PendingClose({
    required this.date,
    required this.habit1Result,
    this.habit2Result,
    this.habit3Result,
    this.reflection,
  });

  /// Fecha LOCAL del día que se cerró (yyyy-mm-dd).
  final DateTime date;
  final HabitResult habit1Result;
  final HabitResult? habit2Result;
  final HabitResult? habit3Result;
  final String? reflection;

  /// Un cierre pendiente solo vale SU día: si al reintentar ya es otro,
  /// se descarta en silencio — el silencio nunca castiga ni reprocha.
  bool isStale(DateTime now) =>
      date.year != now.year || date.month != now.month || date.day != now.day;
}

/// Persistencia del cierre pendiente en `shared_preferences` (máximo uno:
/// solo puede haber un cierre por día, GUARD_SESSION_01).
class PendingCloseStore {
  static const _key = 'pending_day_close_v1';

  Future<void> save(PendingClose pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [
      '${pending.date.year.toString().padLeft(4, '0')}-'
          '${pending.date.month.toString().padLeft(2, '0')}-'
          '${pending.date.day.toString().padLeft(2, '0')}',
      pending.habit1Result.wireValue,
      pending.habit2Result?.wireValue ?? '',
      pending.habit3Result?.wireValue ?? '',
      pending.reflection ?? '',
    ]);
  }

  Future<PendingClose?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null || raw.length != 5) return null;
    try {
      return PendingClose(
        date: DateTime.parse(raw[0]),
        habit1Result: HabitResult.fromWire(raw[1]),
        habit2Result: raw[2].isEmpty ? null : HabitResult.fromWire(raw[2]),
        habit3Result: raw[3].isEmpty ? null : HabitResult.fromWire(raw[3]),
        reflection: raw[4].isEmpty ? null : raw[4],
      );
    } catch (_) {
      // Dato corrupto (fecha o enum irreconocible): mejor silencio que crash.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
