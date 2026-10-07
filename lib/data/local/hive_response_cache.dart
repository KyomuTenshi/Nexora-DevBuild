import 'package:hive_ce/hive.dart';
import 'package:nexora/data/api/response_cache.dart';

/// Кэш ответов API на диске (Hive). Хранит последние [maxEntries] ответов.
/// Значение: время сохранения, перевод строки и сам текст ответа.
class HiveResponseCache implements ResponseCache {
  HiveResponseCache(this._box, {this.maxEntries = 80});

  final Box<String> _box;
  final int maxEntries;

  @override
  String? read(String key) {
    final raw = _box.get(_hash(key));
    if (raw == null) return null;
    final split = raw.indexOf('\n');
    return split < 0 ? null : raw.substring(split + 1);
  }

  @override
  Future<void> write(String key, String body) async {
    await _box.put(
      _hash(key),
      '${DateTime.now().millisecondsSinceEpoch}\n$body',
    );
    if (_box.length > maxEntries) await _prune();
  }

  /// Удаляет самые старые ответы, пока не останется [maxEntries].
  Future<void> _prune() async {
    final entries = <MapEntry<dynamic, int>>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      var time = 0;
      if (raw != null) {
        final split = raw.indexOf('\n');
        if (split > 0) time = int.tryParse(raw.substring(0, split)) ?? 0;
      }
      entries.add(MapEntry(key, time));
    }
    entries.sort((a, b) => a.value.compareTo(b.value));
    final extra = entries.length - maxEntries;
    if (extra > 0) {
      await _box.deleteAll(entries.take(extra).map((e) => e.key));
    }
  }

  /// Ключи Hive ограничены 255 символами, а адреса запросов длиннее.
  /// Поэтому ключом служит короткий хеш адреса (FNV-1a) плюс его длина.
  static String _hash(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return '${hash.toRadixString(16)}_${key.length}';
  }
}