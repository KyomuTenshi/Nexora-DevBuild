import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/domain/entities/media_item.dart';

/// Избранное: id тайтла -> сам тайтл. Тайтл храним целиком, чтобы страница
/// «Избранное» открывалась сразу и без запроса к API.
/// Стартовые значения как в макете профиля.
class FavoritesNotifier extends Notifier<Map<int, MediaItem>> {
  @override
  Map<int, MediaItem> build() => {
    for (final item in [
      MockData.onePiece,
      MockData.jujutsu,
      MockData.vinland,
    ])
      item.id: item,
  };

  bool isFavorite(int id) => state.containsKey(id);

  void toggle(MediaItem item) {
    // Создаём НОВУЮ карту: Riverpod замечает замену, а не правку на месте.
    if (state.containsKey(item.id)) {
      state = {...state}..remove(item.id);
    } else {
      state = {...state, item.id: item};
    }
  }
}

final favoritesProvider =
NotifierProvider<FavoritesNotifier, Map<int, MediaItem>>(
  FavoritesNotifier.new,
);