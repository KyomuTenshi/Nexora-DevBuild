/// Куда приложение отправляет сведения об ошибках.
abstract interface class CrashReporter {
  /// Записывает ошибку, приложение при этом продолжает работать.
  Future<void> recordError(Object error, StackTrace? stack, {String? reason});

  /// Намеренно роняет приложение: так проверяют, что отчёты доходят.
  void crash();
}
