import 'package:nexora/domain/repositories/crash_reporter.dart';

/// Подставной отправитель отчётов для тестов (и значение по умолчанию в DI).
class FakeCrashReporter implements CrashReporter {
  final List<Object> errors = [];
  int crashes = 0;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    errors.add(error);
  }

  @override
  void crash() => crashes++;
}
