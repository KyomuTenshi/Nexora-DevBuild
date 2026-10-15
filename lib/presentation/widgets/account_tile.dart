import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/core/router/app_router.dart';

class AccountTile extends ConsumerWidget {
  const AccountTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Пока поток не выдал первое значение, берём пользователя напрямую
    final user = ref.watch(authStateProvider).value ??
        ref.read(authRepositoryProvider).currentUser;

    if (user == null) {
      return ListTile(
        leading: const Icon(Icons.login_rounded),
        title: const Text('Войти или зарегистрироваться'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.pushNamed(AppRoute.login),
      );
    }

    return ListTile(
      leading: const Icon(Icons.account_circle_outlined),
      title: Text(user.shownName),
      subtitle: Text(user.email),
      trailing: TextButton(
        onPressed: () => ref.read(authRepositoryProvider).signOut(),
        child: const Text('Выйти'),
      ),
    );
  }
}