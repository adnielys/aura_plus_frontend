import 'package:aura_plus/features/care/presentation/providers/care_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('careReferralFromJson', () {
    test('parsea el contrato completo', () {
      final referral = careReferralFromJson({
        'id': 'r1',
        'provider_id': 'p1',
        'provider_name': 'Doula Ana Ríos',
        'provider_contact': {'type': 'email', 'value': 'ana@x.test'},
        'status': 'offered',
        'provider_response': 'accepted',
        'provider_responded_at': '2026-07-18T10:00:00Z',
        'shared_payload': {'name': 'Adnielys'},
        'created_at': '2026-07-18T09:00:00Z',
      });
      expect(referral.id, 'r1');
      expect(referral.providerName, 'Doula Ana Ríos');
      expect(referral.providerContact?['value'], 'ana@x.test');
      expect(referral.providerResponse, 'accepted');
      expect(referral.sharedPayload?['name'], 'Adnielys');
    });

    test('tolera contacto nulo (aún sin aceptar) y payload nulo (anónima)', () {
      final referral = careReferralFromJson({
        'id': 'r2',
        'provider_id': 'p1',
        'provider_name': 'Prov',
        'provider_contact': null,
        'status': 'offered',
        'provider_response': 'pending',
        'shared_payload': null,
      });
      expect(referral.providerContact, isNull);
      expect(referral.sharedPayload, isNull);
      expect(referral.createdAt, isNull);
    });
  });

  group('filterProviders (buscador D1/D2: se combinan búsqueda y nivel)', () {
    final ana = careProviderFromJson({
      'id': 'p1',
      'tier': 'support',
      'role': 'doula',
      'full_name': 'Doula Ana Ríos',
      'country': 'ES',
      'languages': ['es'],
      'specialties': ['postparto', 'lactancia'],
      'license_verified': false,
    });
    final marta = careProviderFromJson({
      'id': 'p2',
      'tier': 'clinical',
      'role': 'psychologist',
      'full_name': 'Psic. Marta Sol',
      'country': 'ES',
      'languages': ['es', 'en'],
      'specialties': ['salud perinatal'],
      'license_verified': true,
    });
    final all = [ana, marta];

    test('por nombre parcial, sin distinguir mayúsculas ni acentos', () {
      expect(filterProviders(all, query: 'psic'), [marta]);
      expect(filterProviders(all, query: 'rios'), [ana]);
      expect(filterProviders(all, query: 'RÍOS'), [ana]);
    });

    test('por tipo en español (sinónimos del rol interno)', () {
      expect(filterProviders(all, query: 'psicóloga'), [marta]);
      expect(filterProviders(all, query: 'doula'), [ana]);
    });

    test('por especialidad', () {
      expect(filterProviders(all, query: 'lactancia'), [ana]);
    });

    test('búsqueda y nivel se combinan; sin resultados = lista vacía', () {
      expect(filterProviders(all, query: 'sol', tier: 'support'), isEmpty);
      expect(filterProviders(all, query: 'sol', tier: 'clinical'), [marta]);
      expect(filterProviders(all, query: 'nadie-así'), isEmpty);
      expect(filterProviders(all), all); // sin filtros: todas
    });
  });


  group('shortProviderName (copys cercanos: "en manos de Ana")', () {
    test('quita etiquetas entre corchetes y títulos de rol', () {
      expect(shortProviderName('[PRUEBA] Doula Ana Ríos'), 'Ana');
      expect(shortProviderName('Psic. Marta Sol'), 'Marta');
      expect(shortProviderName('Doula Ana Ríos'), 'Ana');
    });

    test('sin título, usa el primer nombre tal cual', () {
      expect(shortProviderName('Valeria Soto'), 'Valeria');
      expect(shortProviderName('Ana'), 'Ana');
    });
  });

  group('resolveCareView (despacho por estado, A2/A4/A5/A6)', () {
    CareReferral referral({
      String status = 'offered',
      String response = 'pending',
    }) =>
        (
          id: 'r',
          providerId: 'p',
          providerName: 'Ana',
          providerContact: null,
          status: status,
          providerResponse: response,
          sharedPayload: null,
          createdAt: null,
        );

    test('sin derivación activa → directorio (A2)', () {
      expect(resolveCareView(null), CareView.directory);
    });

    test('offered+pending → espera sin ansiedad (A4)', () {
      expect(resolveCareView(referral()), CareView.sent);
    });

    test('offered+accepted → dijo que sí (A5)', () {
      expect(resolveCareView(referral(response: 'accepted')),
          CareView.responseAccepted);
    });

    test('offered+declined → salida amable (A5b)', () {
      expect(resolveCareView(referral(response: 'declined')),
          CareView.responseDeclined);
    });

    test('accepted/connected → episodio (A6), gobierne lo que gobierne '
        'provider_response (campo paralelo)', () {
      expect(resolveCareView(referral(status: 'accepted', response: 'accepted')),
          CareView.episode);
      expect(
          resolveCareView(referral(status: 'connected', response: 'accepted')),
          CareView.episode);
      // Incluso si el profesional no respondió, si ELLA avanzó, manda ella.
      expect(resolveCareView(referral(status: 'connected')), CareView.episode);
    });
  });
}
