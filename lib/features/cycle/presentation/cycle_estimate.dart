import 'package:flutter/material.dart';

/// Las cuatro fases del ciclo (metáfora del dominio: winter/spring/summer/
/// autumn). Aquí en clave clínica suave para la vista "My Cycle".
enum CyclePhase { menstrual, follicular, ovulation, luteal }

/// Estimación del ciclo en el FRONTEND con un modelo simple de 28 días, a
/// partir del último inicio de regla. NO es un tracker clínico: es una
/// estimación para pintar la rueda y las tarjetas. El tono manda: siempre
/// "an estimate, never a verdict" (GUARD_MENS_04) — el cuerpo tiene la última
/// palabra. Si no hay fecha registrada, no se estima nada.
class CycleEstimate {
  const CycleEstimate._(this.cycleDay);

  /// Construye desde el último inicio de regla y el "hoy" del usuario.
  factory CycleEstimate.from(DateTime lastPeriodStart, DateTime today) {
    final start = DateTime(
        lastPeriodStart.year, lastPeriodStart.month, lastPeriodStart.day);
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(start).inDays;
    final mod = diff % cycleLength;
    final norm = mod < 0 ? mod + cycleLength : mod;
    return CycleEstimate._(norm + 1); // día 1 = inicio registrado
  }

  /// Largo medio del ciclo y de la regla (modelo; el cuerpo real varía).
  static const int cycleLength = 28;
  static const int periodDays = 5;
  static const int ovulationDay = 14;

  /// Día del ciclo, 1..28.
  final int cycleDay;

  /// Fase de un día cualquiera (para colorear cada punto de la rueda).
  static CyclePhase phaseOf(int day) {
    if (day <= periodDays) return CyclePhase.menstrual;
    if (day < ovulationDay) return CyclePhase.follicular;
    if (day == ovulationDay) return CyclePhase.ovulation;
    return CyclePhase.luteal;
  }

  CyclePhase get phase => phaseOf(cycleDay);

  /// ¿Está en días de regla? (para "Next period: now").
  bool get inPeriod => cycleDay <= periodDays;

  /// Días hasta la ovulación (estimada). 0 = hoy; envuelve al próximo ciclo.
  int get daysToOvulation {
    final d = ovulationDay - cycleDay;
    return d >= 0 ? d : d + cycleLength;
  }

  /// Días hasta la próxima regla; 0 si está reglando ahora.
  int get daysToNextPeriod => inPeriod ? 0 : cycleLength - cycleDay + 1;

  /// Ventana fértil (estimada, suave). Devuelve (nivel corto, frase).
  ({String level, String detail}) get fertility {
    if (cycleDay >= 13 && cycleDay <= 15) {
      return (level: 'Peak', detail: 'Higher chance these days');
    }
    if (cycleDay >= 10 && cycleDay <= 16) {
      return (level: 'High', detail: 'Higher chance around now');
    }
    return (level: 'Low', detail: 'Low chance today');
  }
}

/// Metadatos de presentación por fase (color, nombre, micro-palabra, hero).
/// Centralizados para que la rueda y las tarjetas hablen igual.
extension CyclePhaseVisuals on CyclePhase {
  String get name => switch (this) {
        CyclePhase.menstrual => 'Menstrual',
        CyclePhase.follicular => 'Follicular',
        CyclePhase.ovulation => 'Ovulation',
        CyclePhase.luteal => 'Luteal',
      };

  /// Micro-palabra del pill "Day N of 28 · …".
  String get micro => switch (this) {
        CyclePhase.menstrual => 'rest',
        CyclePhase.follicular => 'rising',
        CyclePhase.ovulation => 'peak',
        CyclePhase.luteal => 'winding down',
      };

  /// Color del punto en la rueda y del acento de la fase.
  Color get color => switch (this) {
        CyclePhase.menstrual => const Color(0xFFB0184A),
        CyclePhase.follicular => const Color(0xFFFF6FA1),
        CyclePhase.ovulation => const Color(0xFF6A5AE0),
        CyclePhase.luteal => const Color(0xFFC9C6CE),
      };

  /// Hero de la fase (mycycle/ciclo{1..4}). Mapeo por imaginería: menstrual =
  /// luna menguante en reposo; follicular = brotes; ovulation = plena luz;
  /// luteal = mano al pecho, repliegue.
  String get heroAsset => switch (this) {
        CyclePhase.menstrual => 'assets/images/cycle/ciclo1.png',
        CyclePhase.follicular => 'assets/images/cycle/ciclo4.png',
        CyclePhase.ovulation => 'assets/images/cycle/ciclo2.png',
        CyclePhase.luteal => 'assets/images/cycle/ciclo3.png',
      };
}
