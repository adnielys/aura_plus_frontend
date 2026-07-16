import '../../../../shared/domain/user_profile.dart';
import '../entities/onboarding_data.dart';

/// Contrato del onboarding para la capa `presentation`.
///
/// Las implementaciones traducen excepciones de transporte/contrato a [Failure]
/// tipadas; la UI nunca ve un DioException crudo.
abstract interface class OnboardingRepository {
  /// ¿La usuaria ya completó el onboarding? (`GET /onboarding/status`).
  Future<bool> isCompleted();

  /// Envía las respuestas y crea el perfil + primera constelación
  /// (`POST /onboarding/complete`). Devuelve el [UserProfile] creado.
  Future<UserProfile> complete(OnboardingData data);

  /// Reinicia el onboarding (`DELETE /onboarding`): borra perfil y
  /// preferencias en el servidor; las estrellas nunca se pierden.
  Future<void> restart();
}
