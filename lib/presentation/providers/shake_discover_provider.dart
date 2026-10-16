import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/device_providers.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/presentation/providers/shake_provider.dart';
import 'package:nexora/presentation/widgets/root_messenger.dart';

final _random = Random();

/// Слушает встряску и открывает случайный тайтл из каталога.
/// Работает только на пяти главных вкладках, чтобы не мешать
/// на странице тайтла, плеере или входе.
final shakeDiscoverProvider = Provider<void>((ref) {
  // Выключили в настройках: ничего не слушаем, датчик не работает
  if (!ref.watch(shakeEnabledProvider)) return;

  var busy = false;

  Future<void> onShake() async {
    if (busy) return;
    busy = true;
    try {
      final router = ref.read(routerProvider);
      final path = router.routerDelegate.currentConfiguration.uri.path;
      if (!kTabPaths.contains(path)) return;

      final items = await ref
          .read(mediaRepositoryProvider)
          .searchCatalog(const CatalogQuery());
      if (!ref.mounted || items.isEmpty) return;

      final item = items[_random.nextInt(items.length)];
      try {
        HapticFeedback.mediumImpact(); // короткая вибрация-отклик
      } catch (_) {}
      router.pushNamed(
        AppRoute.detail,
        pathParameters: {'id': '${item.id}'},
        extra: item,
      );
    } catch (_) {
      rootMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Не удалось подобрать тайтл. Проверьте интернет'),
          ),
        );
    } finally {
      busy = false;
    }
  }

  final subscription = ref
      .watch(shakeRepositoryProvider)
      .shakes
      .listen((_) => onShake(), onError: (Object _) {});
  ref.onDispose(subscription.cancel);
});
