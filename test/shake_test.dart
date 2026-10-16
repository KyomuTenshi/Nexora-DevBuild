import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora/core/di/device_providers.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/di/retry.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/data/repositories/mock_media_repository.dart';
import 'package:nexora/data/sensors/fake_shake_repository.dart';
import 'package:nexora/data/sensors/shake_detector.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/shake_discover_provider.dart';
import 'package:nexora/presentation/providers/shake_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('detectShakes', () {
    test('слабые движения игнорирует, сильные считает с паузой', () async {
      var time = DateTime(2026);
      final input = StreamController<double>();
      var count = 0;
      final sub = detectShakes(
        input.stream,
        threshold: 15,
        cooldown: const Duration(seconds: 1),
        now: () => time,
      ).listen((_) => count++);

      input.add(5); // слабое движение
      await pumpEventQueue();
      expect(count, 0);

      input.add(20); // встряска
      await pumpEventQueue();
      expect(count, 1);

      input.add(25); // то же мгновение: ещё идёт пауза
      await pumpEventQueue();
      expect(count, 1);

      time = time.add(const Duration(seconds: 2)); // пауза прошла
      input.add(20);
      await pumpEventQueue();
      expect(count, 2);

      await sub.cancel();
      await input.close();
    });
  });

  group('shakeEnabledProvider', () {
    test('по умолчанию включён и запоминает выбор', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        retry: noAutoRetry,
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(shakeEnabledProvider), isTrue);

      container.read(shakeEnabledProvider.notifier).setEnabled(false);

      expect(container.read(shakeEnabledProvider), isFalse);
      expect(prefs.getBool('shake_discover'), isFalse);
    });
  });

  group('shakeDiscoverProvider', () {
    // Мини-роутер: пять настоящих вкладок не нужны, важен путь и переход
    GoRouter buildRouter(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/other',
          builder: (_, _) => const Scaffold(body: Text('other')),
        ),
        GoRoute(
          path: '/title/:id',
          name: AppRoute.detail,
          builder: (_, state) => Scaffold(
            body: Text('detail ${(state.extra as MediaItem).title}'),
          ),
        ),
      ],
    );

    Future<FakeShakeRepository> pumpApp(
      WidgetTester tester, {
      required String initial,
      bool enabled = true,
    }) async {
      SharedPreferences.setMockInitialValues({'shake_discover': enabled});
      final prefs = await SharedPreferences.getInstance();
      final shake = FakeShakeRepository();
      final router = buildRouter(initial);

      await tester.pumpWidget(
        ProviderScope(
          retry: noAutoRetry,
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            mediaRepositoryProvider.overrideWithValue(
              MockMediaRepository(
                searchDelay: Duration.zero,
                homeDelay: Duration.zero,
              ),
            ),
            shakeRepositoryProvider.overrideWithValue(shake),
            routerProvider.overrideWithValue(router),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              ref.watch(shakeDiscoverProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return shake;
    }

    testWidgets('встряска на вкладке открывает случайный тайтл', (
      tester,
    ) async {
      final shake = await pumpApp(tester, initial: '/home');

      shake.trigger();
      await tester.pumpAndSettle();

      expect(find.textContaining('detail '), findsOneWidget);
    });

    testWidgets('вне главных вкладок встряска ничего не делает', (
      tester,
    ) async {
      final shake = await pumpApp(tester, initial: '/other');

      shake.trigger();
      await tester.pumpAndSettle();

      expect(find.text('other'), findsOneWidget);
      expect(find.textContaining('detail '), findsNothing);
    });

    testWidgets('при выключенной настройке встряска не слушается', (
      tester,
    ) async {
      final shake = await pumpApp(tester, initial: '/home', enabled: false);

      shake.trigger();
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });
  });
}
