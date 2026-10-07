import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Множество id избранных тайтлов. Стартовые значения как в макете профиля.
class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => <int>{1, 2, 4};

  bool isFavorite(int id) => state.contains(id);

  void toggle(int id) {
    // Создаём НОВОЕ множество: Riverpod замечает замену, а не правку на месте.
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);
