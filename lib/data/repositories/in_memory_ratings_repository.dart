import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/domain/repositories/ratings_repository.dart';

/// Оценки в памяти с одной демо-оценкой. Нужно для тестов и как стартовый
/// набор при первом запуске.
class InMemoryRatingsRepository implements RatingsRepository {
  InMemoryRatingsRepository({bool seeded = true}) {
    if (seeded) _ratings[MockData.jujutsu.id] = 4;
  }

  final Map<int, int> _ratings = {};

  @override
  Map<int, int> getAll() => Map.of(_ratings);

  @override
  Future<void> set(int itemId, int value) async {
    _ratings[itemId] = value;
  }

  @override
  Future<void> remove(int itemId) async {
    _ratings.remove(itemId);
  }
}