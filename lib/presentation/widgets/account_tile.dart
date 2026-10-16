import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/presentation/providers/cloud_sync_provider.dart';

class AccountTile extends ConsumerWidget {
  const AccountTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Пока поток не выдал первое значение, берём пользователя напрямую
    final user = ref.watch(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    final sync = ref.watch(cloudSyncProvider);

    if (user == null) {
      return ListTile(
        leading: const Icon(Icons.login_rounded),
        title: const Text('Войти или зарегистрироваться'),
        subtitle: const Text('Избранное и библиотека сохранятся в облаке'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.pushNamed(AppRoute.login),
      );
    }

    final syncText = switch (sync) {
      SyncStatus.syncing => 'Синхронизация…',
      SyncStatus.done => 'Данные сохранены в облаке',
      SyncStatus.error => 'Не удалось синхронизировать',
      SyncStatus.idle => '',
    };

    return ListTile(
      leading: const Icon(Icons.account_circle_outlined),
      title: Text(user.shownName),
      subtitle: Text(
        syncText.isEmpty ? user.email : '${user.email}\n$syncText',
      ),
      isThreeLine: syncText.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sync == SyncStatus.error)
            IconButton(
              tooltip: 'Повторить',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(cloudSyncProvider.notifier).sync(),
            ),
          TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}