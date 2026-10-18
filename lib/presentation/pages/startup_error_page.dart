import 'package:flutter/material.dart';

/// Показывается вместо чёрного экрана, если приложение не смогло запуститься
/// (например, не подключился Firebase или не открылось хранилище).
/// Текст ошибки можно выделить и скопировать.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error, required this.stack});

  final Object error;
  final StackTrace stack;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Не удалось запустить Nexora',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Сделайте скриншот или скопируйте текст ниже: '
                'по нему видно, что именно сломалось.',
              ),
              const SizedBox(height: 16),
              SelectableText(
                '$error\n\n$stack',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
