import 'package:aura_plus/features/crisis/domain/crisis_resource.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que se prueba aquí no es una funcionalidad: es que a las tres de la
/// mañana haya un número y se pueda marcar.
void main() {
  group('CrisisResource', () {
    test('lee el contrato', () {
      final r = CrisisResource.fromJson({
        'name': 'TelefonSeelsorge',
        'phone': '0800 111 0 111',
        'note': 'kostenlos, anonym, rund um die Uhr',
        'kind': 'listening',
      });
      expect(r.name, 'TelefonSeelsorge');
      expect(r.phone, '0800 111 0 111');
      expect(r.kind, CrisisResourceKind.listening);
    });

    test('un kind desconocido se pinta como escucha, no rompe la pantalla', () {
      final r = CrisisResource.fromJson({
        'name': 'X',
        'phone': '112',
        'kind': 'algo_nuevo',
      });
      expect(r.kind, CrisisResourceKind.listening);
    });

    test('sobrevive al viaje de ida y vuelta por la caché', () {
      const original = CrisisHelp(
        intro: 'Damit bist du nicht allein.',
        resources: [
          CrisisResource(
            name: 'TelefonSeelsorge',
            phone: '0800 111 0 111',
            note: 'kostenlos',
            kind: CrisisResourceKind.listening,
          ),
          CrisisResource(
            name: 'Notruf',
            phone: '112',
            note: null,
            kind: CrisisResourceKind.emergency,
          ),
        ],
        closing: 'Ich bin hier.',
      );

      final revived = CrisisHelp.fromJson(original.toJson());

      expect(revived.intro, original.intro);
      expect(revived.closing, original.closing);
      expect(revived.resources.length, 2);
      expect(revived.resources[0].phone, '0800 111 0 111');
      expect(revived.resources[1].kind, CrisisResourceKind.emergency);
      expect(revived.resources[1].note, isNull);
    });
  });

  group('CrisisHelp', () {
    test('una respuesta rota no explota: queda vacía y el provider degrada',
        () {
      final help = CrisisHelp.fromJson(const {});
      expect(help.resources, isEmpty);
      expect(help.intro, '');
    });
  });
}
