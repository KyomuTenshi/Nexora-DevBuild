import '../entities/library_entry.dart';
import '../entities/media_item.dart';

/// Контракт облачного хранилища пользователя. Данные каждого человека лежат
/// отдельно, поэтому везде передаётся uid. Ошибки сети приходят как
/// NetworkException.
abstract class CloudSyncRepository {
  Future<List<MediaItem>> loadFavorites(String uid);
  Future<void> saveFavorite(String uid, MediaItem item);
  Future<void> removeFavorite(String uid, int itemId);

  Future<List<LibraryEntry>> loadLibrary(String uid);
  Future<void> saveLibraryEntry(String uid, LibraryEntry entry);
  Future<void> removeLibraryEntry(String uid, int itemId);
}
