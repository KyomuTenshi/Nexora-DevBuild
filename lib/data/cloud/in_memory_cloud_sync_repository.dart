import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/repositories/cloud_sync_repository.dart';

/// «Облако» в памяти: по умолчанию и в тестах, без Firebase и сети.
class InMemoryCloudSyncRepository implements CloudSyncRepository {
  final Map<String, Map<int, MediaItem>> _favorites = {};
  final Map<String, Map<int, LibraryEntry>> _library = {};

  /// Для проверок в тестах.
  List<MediaItem> favoritesOf(String uid) =>
      List.of(_favorites[uid]?.values ?? const <MediaItem>[]);

  List<LibraryEntry> libraryOf(String uid) =>
      List.of(_library[uid]?.values ?? const <LibraryEntry>[]);

  @override
  Future<List<MediaItem>> loadFavorites(String uid) async => favoritesOf(uid);

  @override
  Future<void> saveFavorite(String uid, MediaItem item) async {
    (_favorites[uid] ??= {})[item.id] = item;
  }

  @override
  Future<void> removeFavorite(String uid, int itemId) async {
    _favorites[uid]?.remove(itemId);
  }

  @override
  Future<List<LibraryEntry>> loadLibrary(String uid) async => libraryOf(uid);

  @override
  Future<void> saveLibraryEntry(String uid, LibraryEntry entry) async {
    (_library[uid] ??= {})[entry.item.id] = entry;
  }

  @override
  Future<void> removeLibraryEntry(String uid, int itemId) async {
    _library[uid]?.remove(itemId);
  }
}