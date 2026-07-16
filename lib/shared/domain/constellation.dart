/// Constelación = ciclo de 28 días. Entidad pura y transversal (la devuelven
/// `/constellation/*` y `SessionResult`).
///
/// GUARD_TONE_04: solo expone cuánto llevas. `starsEarned` es append-only e
/// ilimitado (puede superar [starsMax], que es un límite VISUAL del dibujo, no
/// un umbral). El cliente nunca recalcula estrellas, solo pinta.
class Constellation {
  const Constellation({
    required this.id,
    required this.name,
    required this.cycleNumber,
    required this.starsEarned,
    required this.starsMax,
    required this.isComplete,
    required this.isCurrent,
    this.completedAt,
    this.daysPresent,
  });

  final String id;
  final String name;
  final int cycleNumber;
  final int starsEarned;
  final int starsMax;
  final bool isComplete;
  final bool isCurrent;

  /// Cuándo se completó el ciclo (null si sigue en curso). Dispara la
  /// celebración en el cliente.
  final DateTime? completedAt;

  /// Días distintos con check-in dentro del ciclo. Solo acumula — jamás se
  /// muestra cuántos faltan (GUARD_TONE_03/04). Null cuando el contexto no lo
  /// calcula (la constelación embebida en `SessionResult`).
  final int? daysPresent;

  /// Estrellas encendidas en el dibujo: `min(starsEarned, starsMax)`.
  int get litStars => starsEarned < starsMax ? starsEarned : starsMax;
}
