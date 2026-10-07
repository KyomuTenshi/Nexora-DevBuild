import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/repositories/favorites_repository.dart';

/// Избранное в памяти с демо-данными (как в макете профиля).
/// Нужно для тестов и как стартовый набор при первом запуске.
class InMemoryFavoritesRepository implements FavoritesRepository {
  InMemoryFavoritesRepository({bool seeded = true}) {
    if (seeded) {
      for (final item in [
        MockData.onePiece,
        MockData.jujutsu,
        MockData.vinland,
      ]) {
        _items[item.id] = item;
      }
    }
  }

  final Map<int, MediaItem> _items = {};

  @override
  List<MediaItem> getAll() => _items.values.toList();

  @override
  Future<void> add(MediaItem item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> remove(int itemId) async {
    _items.remove(itemId);
  }
}