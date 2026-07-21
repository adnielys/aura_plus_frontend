/// LA notificación diaria, programada EN el teléfono (sin Google, sin
/// servidor, sin internet): una sola al día, a su hora, con un copy sereno
/// que rota. GUARD_NOTIF_03 por construcción.
///
/// Se programa una ventana de [_windowDays] días por delante y se refresca en
/// cada arranque y en cada cambio de ajustes — así sobrevive semanas sin
/// abrir la app y también a reinicios del teléfono (BootReceiver).
library;

import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

const _channelId = 'aura_daily';
const _channelName = 'Daily message';
const _channelDescription = 'One gentle message a day, at your chosen time.';
const _idBase = 100;
const _windowDays = 14;

/// Pool de invitaciones serenas (Sistema Emocional: invitar, jamás exigir;
/// el silencio nunca castiga). Rota por día del año — sin repetir seguido.
const dailyMessages = [
  'Your minute is here, whenever you want it.',
  'One small gesture, just for you. No rush.',
  'Your space is open. Come as you are.',
  'A moment for you — even one breath counts.',
  'Nothing to prove today. Just presence.',
  'Aura is here. Today counts, however it went.',
  'Your sky is waiting, no hurry at all.',
];

/// Copy del día: rotación estable por día del año (testeable y sin estado).
String messageForDay(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  return dailyMessages[dayOfYear % dailyMessages.length];
}

final _plugin = FlutterLocalNotificationsPlugin();
bool _ready = false;

Future<void> _ensureReady() async {
  if (_ready) return;
  tzdata.initializeTimeZones();
  try {
    final local = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(local.identifier));
  } catch (_) {
    // Sin identificador válido: tz.local queda en UTC; la hora puede
    // desviarse pero jamás rompe la app.
  }
  await _plugin.initialize(
    settings: const InitializationSettings(
      // Destello ✦ de la marca (blanco: Android lo tiñe de carmesí).
      android: AndroidInitializationSettings('@drawable/ic_stat_aura'),
    ),
  );
  _ready = true;
}

Future<void> _cancelWindow() async {
  for (var i = 0; i < _windowDays; i++) {
    await _plugin.cancel(id: _idBase + i);
  }
}

/// Programa (o cancela) la diaria. [preferredTime] en 'HH:mm'.
///
/// Idempotente: siempre limpia la ventana anterior y, si [enabled], programa
/// los próximos [_windowDays] días a esa hora con el copy rotatorio. Usa
/// alarmas INEXACTAS (pueden desviarse unos minutos): suficiente para una
/// invitación y sin pedir el permiso especial de alarmas exactas.
Future<void> scheduleDailyNotifications({
  required bool enabled,
  required String preferredTime,
}) async {
  try {
    await _ensureReady();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await _cancelWindow();
    if (!enabled) return;

    // Android 13+: permiso explícito. Si dice que no, no se insiste.
    final granted = await android?.requestNotificationsPermission() ?? true;
    if (!granted) return;

    // Exacta si el sistema lo permite (a su hora, de verdad); si no,
    // inexacta (el SO puede desplazarla dentro de su ventana de batch).
    final exactAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    final mode = exactAllowed
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final parts = preferredTime.split(':');
    final hour = int.tryParse(parts[0]) ?? 21;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var slot =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!slot.isAfter(now)) slot = slot.add(const Duration(days: 1));

    for (var i = 0; i < _windowDays; i++) {
      final when = slot.add(Duration(days: i));
      await _plugin.zonedSchedule(
        id: _idBase + i,
        // Sin título: la cabecera ya dice "Aura+" (label de la app); el
        // mensaje va solo, en una línea serena — sin negritas que griten.
        title: null,
        body: messageForDay(when),
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            // Carmesí de marca en icono y acentos del sistema.
            color: Color(0xFFC01448),
          ),
        ),
        androidScheduleMode: mode,
      );
    }
  } catch (_) {
    // Jamás bloquea la app: sin permiso o sin plugin, silencio.
  }
}

/// Al cerrar sesión: la diaria de una cuenta cerrada no debe sonar.
Future<void> cancelDailyNotifications() async {
  try {
    await _ensureReady();
    await _cancelWindow();
  } catch (_) {
    // nada que cancelar
  }
}
