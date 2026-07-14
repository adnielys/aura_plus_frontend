/// Excepción que representa el envelope de error del backend `{success:false, error}`.
///
/// Se lanza al desenvolver una respuesta 2xx cuyo `success` es false. Los errores
/// HTTP (4xx/5xx) llegan como DioException y se traducen en la capa `data`.
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    required this.httpStatus,
  });

  final String code;
  final String message;
  final int httpStatus;

  @override
  String toString() => 'ApiException($code, $httpStatus): $message';
}

/// Desenvuelve el envelope estándar `{success, data, meta}`.
///
/// Devuelve el contenido de `data` (reconciliación #1). Si `success` es false,
/// lanza [ApiException] con el bloque `error`. Si el cuerpo no tiene la forma
/// esperada, lanza [ApiException] con código `malformed_response`.
Object? unwrapEnvelope(Object? body) {
  if (body is! Map) {
    throw const ApiException(
      code: 'malformed_response',
      message: 'Respuesta del servidor con formato inesperado.',
      httpStatus: 0,
    );
  }

  if (body['success'] == true) {
    return body['data'];
  }

  final error = body['error'];
  if (error is Map) {
    throw ApiException(
      code: (error['code'] as String?) ?? 'unknown',
      message: (error['message'] as String?) ?? 'Error desconocido.',
      httpStatus: (error['http_status'] as int?) ?? 0,
    );
  }

  throw const ApiException(
    code: 'malformed_response',
    message: 'Respuesta del servidor con formato inesperado.',
    httpStatus: 0,
  );
}
