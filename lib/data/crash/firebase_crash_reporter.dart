import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:nexora/domain/repositories/crash_reporter.dart';

/// Настоящая отправка отчётов в Firebase Crashlytics.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(Object error, StackTrace? stack, {String? reason}) =>
      _crashlytics.recordError(error, stack, reason: reason);

  @override
  void crash() => _crashlytics.crash();
}
