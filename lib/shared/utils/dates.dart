/// Fechas en español, cercanas — nunca formato de expediente.
library;

const _spanishMonths = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// "18 de julio" — sin año: cercanía, no expediente.
String spanishDate(DateTime date) =>
    '${date.day} de ${_spanishMonths[date.month - 1]}';

const _spanishWeekdays = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

/// "jueves" — día de la semana en español (DateTime.weekday: 1 = lunes).
String spanishWeekday(DateTime date) => _spanishWeekdays[date.weekday - 1];

/// "hoy" / "ayer" / "18 de julio" — para listas de presencia (Mis áreas M3).
String relativeSpanishDate(DateTime date, DateTime today) {
  final day = DateTime(date.year, date.month, date.day);
  final base = DateTime(today.year, today.month, today.day);
  final difference = base.difference(day).inDays;
  if (difference == 0) return 'hoy';
  if (difference == 1) return 'ayer';
  return spanishDate(date);
}
