import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/core/di/push_providers.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/domain/entities/push_message.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/widgets/root_messenger.dart';

class PushState {
  const PushState({this.permission, this.token});

  /// null — ещё спрашиваем, true — разрешили, false — запретили.
  final bool? permission;
  final String? token;
}

/// Подключает push к приложению: просит разрешение, получает токен,
/// запоминает его за аккаунтом, показывает сообщения и открывает нужный экран.
class PushNotifier extends Notifier<PushState> {
  final List<StreamSubscription<Object?>> _subscriptions = [];

  @override
  PushState build() {
    final repo = ref.read(pushRepositoryProvider);

    _subscriptions.addAll([
      repo.onForegroundMessage().listen(_onForeground),
      repo.onMessageOpened().listen(_open),
      repo.onTokenRefresh().listen((token) {
        state = PushState(permission: state.permission, token: token);
        _saveToken();
      }),
    ]);
    ref.onDispose(() {
      for (final s in _subscriptions) {
        s.cancel();
      }
    });

    // После входа в аккаунт привязываем к нему этот телефон
    ref.listen(authStateProvider, (_, next) {
      if (next.value != null) _saveToken();
    });

    Future.microtask(_init);
    return const PushState();
  }

  Future<void> _init() async {
    final repo = ref.read(pushRepositoryProvider);
    final granted = await repo.requestPermission();
    final token = granted ? await repo.getToken() : null;
    state = PushState(permission: granted, token: token);
    _saveToken();

    // Приложение могли запустить нажатием на уведомление
    final initial = await repo.getInitialMessage();
    if (initial != null) _open(initial);
  }

  void _saveToken() {
    final token = state.token;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (token == null || user == null) return;
    // Не ждём: без сети запись встанет в очередь Firestore
    unawaited(
      ref
          .read(pushRepositoryProvider)
          .saveToken(uid: user.uid, token: token)
          .catchError((Object _) {}),
    );
  }

  /// Приложение открыто: кладём сообщение в «Уведомления» и показываем плашку.
  void _onForeground(PushMessage message) {
    ref
        .read(notificationsProvider.notifier)
        .addIncoming(title: message.title, message: message.body);
    rootMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message.body.isEmpty
                ? message.title
                : '${message.title}: ${message.body}',
          ),
        ),
      );
  }

  /// Нажали на уведомление: открываем экран из данных сообщения.
  /// Принимаем только известные адреса, чужие значения игнорируем.
  void _open(PushMessage message) {
    ref
        .read(notificationsProvider.notifier)
        .addIncoming(title: message.title, message: message.body);
    final route = message.data['route'];
    if (route != null && kTabPaths.contains(route)) {
      ref.read(routerProvider).go(route);
    }
  }
}

final pushProvider = NotifierProvider<PushNotifier, PushState>(
  PushNotifier.new,
);
