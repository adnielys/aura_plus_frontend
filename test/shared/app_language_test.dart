import 'package:aura_plus/shared/data/models/user_profile_model.dart';
import 'package:aura_plus/shared/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// El idioma es lo primero que decide si ella entiende lo que Aura le dice.
/// Aquí se fija el mapeo teléfono -> contrato, que es donde es fácil fallar.
void main() {
  group('AppLanguage.fromLocale', () {
    test('un alemán de Austria o de Alemania es alemán', () {
      expect(AppLanguage.fromLocale('de'), AppLanguage.de);
      expect(AppLanguage.fromLocale('de_AT'), AppLanguage.de);
      expect(AppLanguage.fromLocale('de-DE'), AppLanguage.de);
    });

    test('el español de cualquier país es español', () {
      expect(AppLanguage.fromLocale('es'), AppLanguage.es);
      expect(AppLanguage.fromLocale('es_MX'), AppLanguage.es);
    });

    test('lo que todavía no hablamos cae a inglés, no a un error', () {
      expect(AppLanguage.fromLocale('fr'), AppLanguage.en);
      expect(AppLanguage.fromLocale('tr_TR'), AppLanguage.en);
      expect(AppLanguage.fromLocale(''), AppLanguage.en);
    });
  });

  group('perfil', () {
    Map<String, Object?> profileJson({String? lang}) => {
          'id': 'a3f1',
          'name': 'Lena',
          'children_count': 1,
          'children_ages': <String>[],
          'main_pain': null,
          'daily_time_slot': 'short',
          'preferred_moment': 'night',
          'message_style': 'warm',
          'onboarding_completed': true,
          'lang': ?lang,
        };

    test('lee el idioma del contrato', () {
      expect(
        UserProfileModel.fromJson(profileJson(lang: 'de')).lang,
        AppLanguage.de,
      );
    });

    test('un servidor viejo sin el campo no rompe el perfil', () {
      expect(UserProfileModel.fromJson(profileJson()).lang, AppLanguage.en);
    });

    test('un idioma que no conocemos tampoco lo rompe', () {
      expect(
        UserProfileModel.fromJson(profileJson(lang: 'pt')).lang,
        AppLanguage.en,
      );
    });
  });
}
