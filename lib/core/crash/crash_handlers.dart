import 'dart:ui' as ui;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Подключает Crashlytics ко всем необработанным ошибкам приложения.
Future<void> setUpCrashReporting(FirebaseCrashlytics crashlytics) async {
  // В отладке отчёты не отправляем, чтобы не засорять консоль Firebase
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  // Ошибки Flutter: показываем в консоли как обычно и отправляем в Crashlytics
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    crashlytics.recordFlutterFatalError(details);
  };

  // Ошибки вне Flutter: асинхронный код, платформенные вызовы
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    // В отладке отдаём ошибку дальше, чтобы увидеть её в консоли
    return !kDebugMode;
  };
}
