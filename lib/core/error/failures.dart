/// Errores de dominio tipados que la capa `presentation` puede mostrar al usuario.
///
/// La capa `data` traduce excepciones de transporte (DioException) y del contrato
/// (ApiException) a estas `Failure`. La UI nunca ve un DioException crudo.
sealed class Failure implements Exception {
  const Failure(this.message);

  /// Mensaje apto para mostrar al usuario (tono de acompañamiento, sin culpa).
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// El backend respondió con un error de negocio (envelope `{success:false, error}`).
final class ApiFailure extends Failure {
  const ApiFailure({
    required this.code,
    required String message,
    required this.httpStatus,
  }) : super(message);

  final String code;
  final int httpStatus;
}

/// No se pudo contactar al backend (sin red, timeout, host caído).
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = "We couldn't connect. Try again in a moment."]);
}

/// Cualquier otra cosa inesperada.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = "Something didn't go as expected."]);
}
