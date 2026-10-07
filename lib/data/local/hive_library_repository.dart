import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:nexora/data/local/stored_json.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/repositories/library_repository.dart';

/// Библиотека пользователя на диске (Hive). Одна запись на тайтл:
/// ключ — id тайтла, значение — JSON. Благодаря этому библиотека, прогресс и
/// «Продолжить просмотр» переживают перезапуск приложения и работают без сети.
class HiveLibraryRepository implements LibraryRepository {
  HiveLibraryRepository(this._box);

  final Box<String> _box;

  /// Служебная запись: «демо-данные уже добавлялись». Ключи тайтлов — числа,
  /// поэтому с этим ключом они не пересекаются.
  static const _seededKey = '_seeded';

  /// При самом первом запуске кладёт стартовые демо-записи. Если пользователь
  /// потом всё удалит, они второй раз не вернутся.
  Future<void> seedIfFirstRun(List<LibraryEntry> entries) async {
    if (_box.containsKey(_seededKey)) return;
    await _box.putAll({
      for (final entry in entries)
        '${entry.item.id}': jsonEncode(libraryEntryToJson(entry)),
      _seededKey: '1',
    });
  }

  @override
  List<LibraryEntry> getAll() {
    final result = <LibraryEntry>[];
    for (final key in _box.keys) {
      if (key == _seededKey) continue;
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        result.add(libraryEntryFromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Повреждённую запись пропускаем, остальные остаются
      }
    }
    // Hive не гарантирует порядок ключей, поэтому сортируем сами: свежие первыми
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  @override
  Future<void> upsert(LibraryEntry entry) =>
      _box.put('${entry.item.id}', jsonEncode(libraryEntryToJson(entry)));

  @override
  Future<void> remove(int itemId) => _box.delete('$itemId');
}