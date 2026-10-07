import '../entities/media_item.dart';

/// Контракт хранилища избранного. Тайтл хранится целиком, чтобы список
/// «Избранное» открывался сразу и без сети.
abstract class FavoritesRepository {
  /// Избранное в порядке добавления (старые первыми).
  List<MediaItem> getAll();
  Future<void> add(MediaItem item);
  Future<void> remove(int itemId);
}