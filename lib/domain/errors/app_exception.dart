/// Ошибки, которые умеет различать приложение. Экраны показывают по ним
/// понятный текст, а не «Exception: что-то пошло не так».
sealed class AppException implements Exception {
  const AppException(this.message);

  /// Техническое описание для логов и отладки.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Нет интернета, обрыв соединения или сервер не ответил за отведённое время.
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Сервис просит делать запросы реже (HTTP 429).
class RateLimitException extends AppException {
  const RateLimitException() : super('Слишком много запросов (HTTP 429)');
}

/// Сервер ответил ошибкой (HTTP 4xx или 5xx).
class ServerException extends AppException {
  const ServerException(this.statusCode)
      : super('Сервер ответил кодом $statusCode');

  final int statusCode;
}

/// Ответ пришёл, но формат не тот, что мы ожидали.
class ParseException extends AppException {
  const ParseException(super.message);
}