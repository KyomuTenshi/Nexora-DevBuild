import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/router/app_router.dart';

/// Переключение вкладок нижнего меню: 0 главная, 1 каталог, 2 библиотека,
/// 3 уведомления, 4 меню.
///
/// Вызовы setTab(...) по всему приложению остались прежними, но теперь
/// вкладку выбирает роутер (context.go), а состояние здесь лишь повторяет
/// её номер.
class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    if (index < 0 || index >= kTabPaths.length) return;
    state = index;
    ref.read(routerProvider).go(kTabPaths[index]);
  }
}

final shellTabProvider = NotifierProvider<ShellTabNotifier, int>(
  ShellTabNotifier.new,
);

/// Сигнал «поставь курсор в поиск каталога». Каждый вызов request()
/// увеличивает число, а поиск замечает изменение и берёт фокус.
class SearchFocusNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final searchFocusProvider = NotifierProvider<SearchFocusNotifier, int>(
  SearchFocusNotifier.new,
);
