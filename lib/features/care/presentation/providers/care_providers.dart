/// Carril B · Etapa 1. Estado del puente humano.
///
/// Reglas de producto que esta capa RESPETA (no reinterpreta):
/// - `providerResponse` es un campo PARALELO del profesional: jamás mueve la
///   máquina de estados de ella (`status`), que solo avanza por sus acciones.
/// - El contacto del profesional llega del servidor SOLO tras su "sí"
///   (provider_response=accepted); el cliente nunca lo conoce antes.
/// - Nada de care llega por push: la app consulta al entrar (GUARD_CARE_09).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_envelope.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/utils/text_search.dart';

/// Profesional del directorio (`GET /care/providers`). Sin contacto: se revela
/// dentro de la derivación cuando acepta.
typedef CareProviderInfo = ({
  String id,
  String tier, // 'support' | 'clinical'
  String role,
  String fullName,
  String country,
  List<String> languages,
  List<String> specialties,
  bool licenseVerified,
});

/// Derivación de la usuaria (`GET /care/referral/current`).
typedef CareReferral = ({
  String id,
  String? providerId,
  String? providerName,
  Map<String, Object?>? providerContact, // solo con providerResponse=accepted
  String status, // offered|accepted|connected (las terminales no llegan aquí)
  String providerResponse, // pending|accepted|declined
  Map<String, Object?>? sharedPayload,
  DateTime? createdAt,
});

CareProviderInfo careProviderFromJson(Map<Object?, Object?> json) => (
      id: json['id'] as String,
      tier: json['tier'] as String,
      role: json['role'] as String,
      fullName: json['full_name'] as String,
      country: json['country'] as String,
      languages: [...(json['languages'] as List? ?? const []).cast<String>()],
      specialties:
          [...(json['specialties'] as List? ?? const []).cast<String>()],
      licenseVerified: (json['license_verified'] as bool?) ?? false,
    );

CareReferral careReferralFromJson(Map<Object?, Object?> json) => (
      id: json['id'] as String,
      providerId: json['provider_id'] as String?,
      providerName: json['provider_name'] as String?,
      providerContact:
          (json['provider_contact'] as Map?)?.cast<String, Object?>(),
      status: json['status'] as String,
      providerResponse: (json['provider_response'] as String?) ?? 'pending',
      sharedPayload: (json['shared_payload'] as Map?)?.cast<String, Object?>(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );

// Prefijos de cortesía/rol que no forman parte del nombre de pila.
const _providerTitles = {
  'doula', 'psic.', 'psic', 'dra.', 'dra', 'dr.', 'dr',
  'matrona', 'enf.', 'enf', 'lic.', 'lic',
};

/// Nombre corto y cercano del profesional para los copys emocionales
/// ("en manos de Ana", "Ana aceptó ✦"). La tarjeta conserva el nombre
/// completo; aquí se quitan etiquetas entre corchetes y títulos de rol.
String shortProviderName(String fullName) {
  final words = fullName
      .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  for (final word in words) {
    if (!_providerTitles.contains(word.toLowerCase())) return word;
  }
  return words.isEmpty ? fullName : words.first;
}

// ── búsqueda del directorio (D1/D2) ─────────────────────────────────────────
// Sinónimos en español del rol interno (espejo del backend): ella escribe
// "psicóloga", no "psychologist".
const _roleSynonyms = {
  'doula': ['doula'],
  'midwife': ['matrona', 'partera', 'comadrona'],
  'peer': ['acompanante', 'par', 'madre'],
  'psychologist': ['psicologa', 'psicologo', 'psicologia'],
  'psychiatrist': ['psiquiatra', 'psiquiatria'],
};

/// Filtro en vivo del directorio: [query] busca en nombre, rol (con sinónimos
/// en español) y especialidades; [tier] restringe por nivel. Se combinan.
List<CareProviderInfo> filterProviders(
  List<CareProviderInfo> providers, {
  String query = '',
  String? tier,
}) {
  final folded = foldSearch(query.trim());
  return [
    for (final provider in providers)
      if ((tier == null || provider.tier == tier) &&
          (folded.isEmpty ||
              foldSearch([
                provider.fullName,
                provider.role,
                ...?_roleSynonyms[provider.role],
                ...provider.specialties,
              ].join(' '))
                  .contains(folded)))
        provider,
  ];
}

const _spanishMonths = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio',
  'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// "18 de julio" — para la línea meta de D4 (sin año: cercanía, no expediente).
String spanishDate(DateTime date) =>
    '${date.day} de ${_spanishMonths[date.month - 1]}';

/// Qué vista del flujo care corresponde al estado actual (A2/A4/A5/A6).
enum CareView { directory, sent, responseAccepted, responseDeclined, episode }

/// Despacho puro de vista por estado — la pantalla solo pinta lo que esto diga.
///
/// offered+pending → espera sin ansiedad (A4) · offered+accepted → "dijo que
/// sí" (A5) · offered+declined → salida amable (A5b) · accepted|connected →
/// episodio en curso (A6). Sin derivación activa → directorio (A2).
CareView resolveCareView(CareReferral? referral) {
  if (referral == null) return CareView.directory;
  if (referral.status == 'accepted' || referral.status == 'connected') {
    return CareView.episode;
  }
  return switch (referral.providerResponse) {
    'accepted' => CareView.responseAccepted,
    'declined' => CareView.responseDeclined,
    _ => CareView.sent,
  };
}

/// Directorio de profesionales (solo visibles: activos, consentidos, y los
/// clínicos siempre con licencia verificada — GUARD_CARE_08 lo filtra el
/// servidor).
final careDirectoryProvider =
    FutureProvider<List<CareProviderInfo>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/care/providers');
  final body = unwrapEnvelope(response.data);
  return [
    for (final item in (body as List? ?? const []))
      careProviderFromJson(item as Map),
  ];
});

/// Derivación ACTIVA (o null → la fila del perfil en reposo). Se consulta al
/// entrar al perfil o al flujo care; jamás hay push de care (GUARD_CARE_09).
final careCurrentReferralProvider = FutureProvider<CareReferral?>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<Object?>('/care/referral/current');
  final body = unwrapEnvelope(response.data);
  return body == null ? null : careReferralFromJson(body as Map);
});

/// Crea la petición (`POST /care/referral`). Con [shareName] adjunta el
/// consentimiento (se comparte SOLO su nombre y que pidió apoyo); sin él, la
/// petición llega anónima — llega igual. El servidor envía el email al
/// profesional con los enlaces mágicos.
Future<void> createCareReferral(
  WidgetRef ref, {
  required String providerId,
  required bool shareName,
}) async {
  final dio = ref.read(dioProvider);
  final response = await dio.post<Object?>('/care/referral', data: {
    'provider_id': providerId,
    if (shareName)
      'consent': {
        'scope': 'share_with_professional',
        'policy_version': 'v1',
      },
  });
  unwrapEnvelope(response.data);
  ref.invalidate(careCurrentReferralProvider);
}

/// Avanza SU máquina de estados (`PATCH /care/referral/{id}`). Devuelve el
/// `closing_message` (CARE_CLOSE) solo al cerrar; null en cualquier otro caso.
Future<String?> advanceCareReferral(
  WidgetRef ref, {
  required String referralId,
  required String status,
  String? closeOutcome,
}) async {
  final dio = ref.read(dioProvider);
  final response = await dio.patch<Object?>(
    '/care/referral/$referralId',
    data: {
      'status': status,
      'close_outcome': ?closeOutcome,
    },
  );
  final body = unwrapEnvelope(response.data) as Map;
  ref.invalidate(careCurrentReferralProvider);
  return body['closing_message'] as String?;
}
