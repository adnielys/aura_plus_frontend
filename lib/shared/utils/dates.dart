/// Fechas cercanas para la UI (en inglés) — nunca formato de expediente.
library;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December',
];

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
  'Saturday', 'Sunday',
];

/// "July 18" — sin año: cercanía, no expediente.
String prettyDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';

/// "Thursday" — día de la semana (DateTime.weekday: 1 = lunes).
String weekdayName(DateTime date) => _weekdays[date.weekday - 1];

/// "today" / "yesterday" / "July 18" — para listas de presencia.
String relativeDate(DateTime date, DateTime today) {
  final day = DateTime(date.year, date.month, date.day);
  final base = DateTime(today.year, today.month, today.day);
  final difference = base.difference(day).inDays;
  if (difference == 0) return 'today';
  if (difference == 1) return 'yesterday';
  return prettyDate(date);
}
