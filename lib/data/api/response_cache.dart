/// Постоянный кэш ответов API: нужен, чтобы приложение показывало последние
/// загруженные данные, когда сети нет. Ключ — полный адрес запроса.
abstract class ResponseCache {
  /// Сохранённый текст ответа или null, если такого запроса ещё не было.
  String? read(String key);

  Future<void> write(String key, String body);
}