import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Какая вкладка нижнего меню открыта: 0 главная, 1 каталог, 2 библиотека,
/// 3 уведомления, 4 профиль.
class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) {
    if (index >= 0 && index <= 4) {
      state = index;
    }
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
