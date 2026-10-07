import 'package:hive_ce/hive.dart';
import 'package:nexora/domain/repositories/ratings_repository.dart';

/// Оценки пользователя на диске (Hive): ключ — id тайтла, значение — оценка.
class HiveRatingsRepository implements RatingsRepository {
  HiveRatingsRepository(this._box);

  final Box<String> _box;

  static const _seededKey = '_seeded';

  /// При первом запуске кладёт стартовые оценки.
  Future<void> seedIfFirstRun(Map<int, int> ratings) async {
    if (_box.containsKey(_seededKey)) return;
    await _box.putAll({
      for (final e in ratings.entries) '${e.key}': '${e.value}',
      _seededKey: '1',
    });
  }

  @override
  Map<int, int> getAll() {
    final result = <int, int>{};
    for (final key in _box.keys) {
      if (key == _seededKey) continue;
      final id = int.tryParse('$key');
      final value = int.tryParse(_box.get(key) ?? '');
      if (id != null && value != null) result[id] = value;
    }
    return result;
  }

  @override
  Future<void> set(int itemId, int value) => _box.put('$itemId', '$value');

  @override
  Future<void> remove(int itemId) => _box.delete('$itemId');
}