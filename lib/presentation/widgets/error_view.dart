import 'package:flutter/material.dart';
import 'package:nexora/domain/errors/app_exception.dart';

/// Экран ошибки: Причина, Решение и кнопка «Повторить».
/// Тексты зависят от типа ошибки, поэтому человек понимает, что делать.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.error});

  final VoidCallback onRetry;

  /// Что именно произошло. Если не передать, покажется общий текст.
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = _describe(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, size: 56, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              info.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              info.hint,
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }

  static ({IconData icon, String title, String hint}) _describe(Object? e) {
    return switch (e) {
      NetworkException() => (
      icon: Icons.wifi_off_rounded,
      title: 'Нет соединения',
      hint: 'Проверьте интернет и нажмите «Повторить».',
      ),
      RateLimitException() => (
      icon: Icons.hourglass_top_rounded,
      title: 'Слишком много запросов',
      hint: 'Сервис просит подождать. Повторите через несколько секунд.',
      ),
      ServerException(:final statusCode) => (
      icon: Icons.cloud_off_rounded,
      title: 'Сервер временно недоступен',
      hint: 'Это не ваша вина (код $statusCode). Попробуйте чуть позже.',
      ),
      ParseException() => (
      icon: Icons.report_problem_outlined,
      title: 'Неожиданный ответ сервера',
      hint: 'Данные пришли в неизвестном формате. Попробуйте позже.',
      ),
      _ => (
      icon: Icons.error_outline_rounded,
      title: 'Не удалось загрузить данные',
      hint: 'Проверьте подключение к интернету.',
      ),
    };
  }
}