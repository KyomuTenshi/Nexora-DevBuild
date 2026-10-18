import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/crash/fake_crash_reporter.dart';
import 'package:nexora/domain/repositories/crash_reporter.dart';

/// По умолчанию подставная реализация (тесты). Настоящий Crashlytics
/// подключается в main().
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => FakeCrashReporter(),
);
