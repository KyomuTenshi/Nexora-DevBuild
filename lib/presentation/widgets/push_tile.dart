import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/push_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

/// Состояние push-уведомлений. В режиме разработчика ([showToken]) ещё и
/// копирование токена устройства: он нужен, чтобы отправить тестовое
/// сообщение из консоли Firebase.
class PushTile extends ConsumerWidget {
  const PushTile({super.key, this.showToken = false});

  final bool showToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushProvider);

    final status = switch (push.permission) {
      null => 'Проверяем разрешение…',
      false => 'Выключены. Разрешите их в настройках телефона',
      true =>
        push.token == null
            ? 'Токен недоступен (нужны сервисы Google Play)'
            : 'Включены',
    };

    return ListTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: const Text('Push-уведомления'),
      subtitle: Text(status),
      trailing: !showToken || push.token == null
          ? null
          : IconButton(
              tooltip: 'Скопировать токен',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: push.token!));
                if (context.mounted) showInfo(context, 'Токен скопирован');
              },
            ),
    );
  }
}
