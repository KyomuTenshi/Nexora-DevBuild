import '../entities/catalog_query.dart';
import '../entities/home_feed.dart';
import '../entities/media_item.dart';

/// Контракт: ЧТО умеет репозиторий, но не КАК.
abstract class MediaRepository {
  Future<HomeFeed> getHomeFeed();
  Future<List<MediaItem>> searchCatalog(CatalogQuery query);
}