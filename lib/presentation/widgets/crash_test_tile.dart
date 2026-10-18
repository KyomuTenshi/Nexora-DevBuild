import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/crash_providers.dart';
import 'package:nexora/domain/repositories/crash_reporter.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

/// Проверка Crashlytics из настроек: тестовая ошибка и тестовое падение.
class CrashTestTile extends ConsumerWidget {
  const CrashTestTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final reporter = ref.read(crashReporterProvider);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Тестовая ошибка (Crashlytics)'),
          subtitle: const Text('Отправит отчёт, приложение не закроется'),
          onTap: () async {
            await reporter.recordError(
              Exception('Тестовая ошибка Nexora'),
              StackTrace.current,
              reason: 'Ручная проверка Crashlytics',
            );
            if (context.mounted) {
              showInfo(
                context,
                'Отчёт отправлен. В консоли Firebase он появится через несколько минут',
              );
            }
          },
        ),
        const Divider(indent: 56),
        ListTile(
          leading: Icon(Icons.warning_amber_rounded, color: scheme.error),
          title: Text(
            'Тестовое падение',
            style: TextStyle(color: scheme.error),
          ),
          subtitle: const Text(
            'Приложение закроется, отчёт придёт при следующем запуске',
          ),
          onTap: () => _confirmCrash(context, reporter),
        ),
      ],
    );
  }

  Future<void> _confirmCrash(
    BuildContext context,
    CrashReporter reporter,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Уронить приложение?'),
        content: const Text(
          'Приложение закроется. Так мы проверяем, что Crashlytics '
          'получает отчёты о сбоях.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Уронить'),
          ),
        ],
      ),
    );
    if (ok == true) reporter.crash();
  }
}
