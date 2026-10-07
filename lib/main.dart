import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/di/providers.dart';

Future<void> main() async {
  // Нужно, чтобы вызывать платформенный код до runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Настройки читаем один раз при старте: дальше доступ к ним синхронный
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // ProviderScope хранит все Riverpod-провайдеры приложения
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const NexoraApp(),
    ),
  );
}
