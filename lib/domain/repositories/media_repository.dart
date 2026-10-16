import '../entities/catalog_query.dart';
import '../entities/catalog_result_page.dart';
import '../entities/home_feed.dart';
import '../entities/media_item.dart';

/// Контракт: ЧТО умеет репозиторий, но не КАК.
/// Ошибки сети и сервера приходят как исключения [AppException].
abstract class MediaRepository {
  Future<HomeFeed> getHomeFeed();

  /// Первая страница каталога обычным списком (подсказки поиска, «Похожие»).
  Future<List<MediaItem>> searchCatalog(CatalogQuery query);

  /// Одна страница каталога (нумерация с 0) и признак, что за ней есть ещё.
  Future<CatalogResultPage> searchCatalogPage(
      CatalogQuery query, {
        int page = 0,
      });

  /// Находит ссылку на обложку для тайтла, у которого её ещё нет
  /// (например, для демо-записей библиотеки). При сбое возвращает null.
  Future<String?> findCoverUrl(MediaItem item);

  /// Забывает закэшированные ответы. Нужно для «потяни, чтобы обновить».
  void clearCache();
}