import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/media_item.dart';

/// Избранное: id тайтла -> сам тайтл. Тайтл храним целиком, чтобы страница
/// «Избранное» открывалась сразу и без запроса к API.
/// Состояние обновляется сразу (оптимистично), а хранилище догоняет следом.
class FavoritesNotifier extends Notifier<Map<int, MediaItem>> {
  @override
  Map<int, MediaItem> build() {
    final repository = ref.read(favoritesRepositoryProvider);
    return {for (final item in repository.getAll()) item.id: item};
  }

  bool isFavorite(int id) => state.containsKey(id);

  void toggle(MediaItem item) {
    final repository = ref.read(favoritesRepositoryProvider);
    // Создаём НОВУЮ карту: Riverpod замечает замену, а не правку на месте.
    if (state.containsKey(item.id)) {
      state = {...state}..remove(item.id);
      unawaited(repository.remove(item.id));
    } else {
      state = {...state, item.id: item};
      unawaited(repository.add(item));
    }
  }
}

final favoritesProvider =
NotifierProvider<FavoritesNotifier, Map<int, MediaItem>>(
  FavoritesNotifier.new,
);