import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/home_feed.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/repositories/media_repository.dart';

/// Тестовый репозиторий. На этапе 5 появится реальный API-репозиторий.
class MockMediaRepository implements MediaRepository {
  MockMediaRepository({
    this.homeDelay = const Duration(milliseconds: 600),
    this.searchDelay = const Duration(milliseconds: 350),
  });

  final Duration homeDelay;
  final Duration searchDelay;

  @override
  Future<HomeFeed> getHomeFeed() async {
    await Future<void>.delayed(homeDelay);

    return const HomeFeed(
      featured: [
        FeaturedBanner(
          item: MockData.jujutsu,
          badge: 'Новый сезон',
          caption: 'Сезон 2 · Action · Fantasy',
        ),
        FeaturedBanner(
          item: MockData.soloLeveling,
          badge: 'Новая серия',
          caption: 'Серия 9 · Action · Fantasy',
        ),
        FeaturedBanner(
          item: MockData.vinland,
          badge: 'Выбор редакции',
          caption: 'Сезон 2 · Action · Drama',
        ),
      ],
      popular: [
        MockData.onePiece,
        MockData.jujutsu,
        MockData.soloLeveling,
        MockData.vinland,
        MockData.edgerunners,
        MockData.frieren,
      ],
    );
  }

  @override
  Future<List<MediaItem>> searchCatalog(CatalogQuery query) async {
    await Future<void>.delayed(searchDelay);

    final text = query.text.trim().toLowerCase();

    final result = MockData.catalog.where((item) {
      if (text.isNotEmpty && !item.title.toLowerCase().contains(text)) {
        return false;
      }
      if (query.genre != null && !item.genres.contains(query.genre)) {
        return false;
      }
      if (query.year != null && item.year != query.year) return false;
      if (query.studio != null && item.studio != query.studio) return false;
      if (query.season != null && item.season != query.season) return false;

      return switch (query.category) {
        CatalogCategory.popular => true,
        CatalogCategory.newest => (item.year ?? 0) >= 2023,
        CatalogCategory.airing => item.status == AiringStatus.airing,
        CatalogCategory.completed => item.status == AiringStatus.finished,
      };
    }).toList();

    switch (query.sort) {
      case CatalogSort.popularity:
        result.sort((a, b) => a.popularity.compareTo(b.popularity));
      case CatalogSort.rating:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case CatalogSort.title:
        result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }
}
