import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/core/di/push_providers.dart';
import 'package:nexora/data/push/fake_push_repository.dart';
import 'package:nexora/data/repositories/in_memory_auth_repository.dart';
import 'package:nexora/domain/entities/push_message.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/providers/push_provider.dart';

Future<void> _pumpEvents() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

/// Включает push так же, как приложение: провайдер остаётся «под наблюдением»
/// (в приложении это ref.watch(pushProvider) в NexoraApp).
void _watchPush(ProviderContainer container) {
  final subscription = container.listen(pushProvider, (_, _) {});
  addTearDown(subscription.close);
}

void main() {
  // Плашка внизу использует GlobalKey, ему нужно окружение Flutter
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'push в открытом приложении попадает в уведомления как непрочитанный',
    () async {
      final push = FakePushRepository();
      addTearDown(push.dispose);
      final container = ProviderContainer(
        overrides: [pushRepositoryProvider.overrideWithValue(push)],
      );
      addTearDown(container.dispose);

      _watchPush(container);
      await _pumpEvents();
      final before = container.read(unreadCountProvider);

      push.emitForeground(
        const PushMessage(title: 'Новая серия', body: 'Вышла серия 5'),
      );
      await _pumpEvents();

      expect(container.read(unreadCountProvider), before + 1);
      final first = container.read(notificationsProvider).first;
      expect(first.title, 'Новая серия');
      expect(first.message, 'Вышла серия 5');
    },
  );

  test('после входа токен устройства запоминается за аккаунтом', () async {
    final push = FakePushRepository(token: 'device-token-1');
    final auth = InMemoryAuthRepository();
    addTearDown(push.dispose);
    addTearDown(auth.dispose);

    final container = ProviderContainer(
      overrides: [
        pushRepositoryProvider.overrideWithValue(push),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);

    _watchPush(container);
    await _pumpEvents();
    expect(container.read(pushProvider).token, 'device-token-1');
    expect(push.savedTokens, isEmpty); // без аккаунта запоминать некому

    await auth.register(email: 'a@b.com', password: 'secret1');
    await _pumpEvents();

    expect(
      push.savedTokens,
      contains((uid: 'a@b.com', token: 'device-token-1')),
    );
  });

  test('если уведомления запрещены, токена нет', () async {
    final push = FakePushRepository(granted: false);
    addTearDown(push.dispose);
    final container = ProviderContainer(
      overrides: [pushRepositoryProvider.overrideWithValue(push)],
    );
    addTearDown(container.dispose);

    _watchPush(container);
    await _pumpEvents();

    expect(container.read(pushProvider).permission, false);
    expect(container.read(pushProvider).token, isNull);
  });
}
