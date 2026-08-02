import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/domain/enums.dart';
import '../../domain/crisis_resource.dart';

const _cacheKey = 'crisis_help_cache';

/// Copia mínima INCRUSTADA en la app. Último recurso cuando no hay red ni
/// caché: el 112, que es cierto en toda la Unión Europea.
///
/// Existe porque quedarse sin NADA en esta pantalla no es una degradación
/// aceptable. Es deliberadamente pobre — los recursos buenos viven en el
/// servidor, que se actualiza sin publicar una versión nueva de la app.
CrisisHelp _embedded(AppLanguage lang) {
  switch (lang) {
    case AppLanguage.de:
      return const CrisisHelp(
        intro: 'Damit bist du nicht allein.',
        resources: [
          CrisisResource(
            name: 'Notruf',
            phone: '112',
            note: 'in der gesamten Europäischen Union',
            kind: CrisisResourceKind.emergency,
          ),
        ],
        closing: 'Ich bin hier, wenn du zurückkommst.',
      );
    case AppLanguage.es:
      return const CrisisHelp(
        intro: 'No hace falta que lo sostengas sola.',
        resources: [
          CrisisResource(
            name: 'Emergencias',
            phone: '112',
            note: 'toda la Unión Europea',
            kind: CrisisResourceKind.emergency,
          ),
        ],
        closing: 'Aquí estaré cuando vuelvas.',
      );
    case AppLanguage.en:
      return const CrisisHelp(
        intro: "You don't have to hold this alone.",
        resources: [
          CrisisResource(
            name: 'Emergency',
            phone: '112',
            note: 'anywhere in the European Union',
            kind: CrisisResourceKind.emergency,
          ),
        ],
        closing: "I'll be here when you come back.",
      );
  }
}

/// Recursos de ayuda inmediata, en tres niveles (SPEC_RECURSOS_CRISIS §4.4).
///
///   1. servidor  ->  2. última respuesta cacheada  ->  3. copia incrustada
///
/// Es la ÚNICA pantalla de Aura+ que debe funcionar en modo avión. Por eso
/// nunca lanza: siempre devuelve algo con un número dentro.
final crisisHelpProvider = FutureProvider<CrisisHelp>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  try {
    final response = await ref.read(dioProvider).get<Object?>('/crisis-resources');
    final help = CrisisHelp.fromJson(unwrapEnvelope(response.data) as Map);
    if (help.resources.isNotEmpty) {
      await prefs.setString(_cacheKey, jsonEncode(help.toJson()));
      return help;
    }
  } catch (_) {
    // Sin red, sin sesión o servidor caído: se sigue a la caché.
  }

  final cached = prefs.getString(_cacheKey);
  if (cached != null) {
    try {
      final help = CrisisHelp.fromJson(jsonDecode(cached) as Map);
      if (help.resources.isNotEmpty) return help;
    } catch (_) {
      // Caché corrupta: se sigue a la copia incrustada.
    }
  }

  return _embedded(
    AppLanguage.fromLocale(PlatformDispatcher.instance.locale.languageCode),
  );
});

/// Abre el marcador con el número puesto. NO llama: ella pulsa.
/// Esa fricción es deliberada — llamar sigue siendo su decisión.
Future<bool> dialNumber(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}
