import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:nexora/data/local/stored_json.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/repositories/favorites_repository.dart';

/// Избранное на диске (Hive). Тайтл хранится целиком вместе со временем
/// добавления, чтобы список открывался без сети и в порядке добавления.
class HiveFavoritesRepository implements FavoritesRepository {
  HiveFavoritesRepository(this._box);

  final Box<String> _box;

  static const _seededKey = '_seeded';

  /// При первом запуске кладёт стартовое избранное (по порядку списка).
  Future<void> seedIfFirstRun(List<MediaItem> items) async {
    if (_box.containsKey(_seededKey)) return;
    // Время ставим «в прошлое», чтобы всё добавленное позже шло после этих
    final start = DateTime.now().millisecondsSinceEpoch - items.length;
    await _box.putAll({
      for (var i = 0; i < items.length; i++)
        '${items[i].id}': _encode(items[i], start + i),
      _seededKey: '1',
    });
  }

  @override
  List<MediaItem> getAll() {
    final found = <({int addedAt, MediaItem item})>[];
    for (final key in _box.keys) {
      if (key == _seededKey) continue;
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        found.add((
        addedAt: json['addedAt'] as int,
        item: mediaItemFromJson(json['item'] as Map<String, dynamic>),
        ));
      } catch (_) {
        // Повреждённую запись пропускаем
      }
    }
    found.sort((a, b) => a.addedAt.compareTo(b.addedAt));
    return [for (final f in found) f.item];
  }

  @override
  Future<void> add(MediaItem item) => _box.put(
    '${item.id}',
    _encode(item, DateTime.now().millisecondsSinceEpoch),
  );

  @override
  Future<void> remove(int itemId) => _box.delete('$itemId');

  String _encode(MediaItem item, int addedAt) =>
      jsonEncode({'addedAt': addedAt, 'item': mediaItemToJson(item)});
}