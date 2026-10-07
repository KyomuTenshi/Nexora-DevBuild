import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/data/api/jikan_client.dart';
import 'package:nexora/data/dto/jikan_dto.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/home_feed.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/media_repository.dart';

/// Репозиторий поверх Jikan (REST API MyAnimeList). Экраны о нём не знают:
/// они работают с интерфейсом [MediaRepository].
class JikanMediaRepository implements MediaRepository {
  JikanMediaRepository(this._client);

  final JikanClient _client;
  final Map<int, Future<String?>> _covers = {};

  @override
  Future<HomeFeed> getHomeFeed() async {
    // Два независимых запроса идут параллельно
    final responses = await Future.wait([
      _client.getJson('/anime', {
        'status': 'airing',
        'order_by': 'popularity',
        'sort': 'asc',
        'type': 'tv',
        'limit': '5',
        'sfw': 'true',
      }),
      _client.getJson('/top/anime', {
        'filter': 'bypopularity',
        'limit': '12',
        'sfw': 'true',
      }),
    ]);

    final airing = _toItems(responses[0], MediaType.anime);
    final popular = _toItems(responses[1], MediaType.anime);

    // Если «сейчас в эфире» пусто, карусель строим из популярного
    final featuredSource = airing.isNotEmpty ? airing : popular.take(3).toList();
    final featured = [
      for (final item in featuredSource)
        FeaturedBanner(
          item: item,
          badge: item.status == AiringStatus.airing ? 'Сейчас в эфире' : 'Популярное',
          caption: [
            if (item.year != null) '${item.year}',
            ...item.genres.take(2),
          ].join(' · '),
        ),
    ];

    return HomeFeed(featured: featured, popular: popular);
  }

  @override
  Future<List<MediaItem>> searchCatalog(CatalogQuery query) async {
    // Студия есть только у аниме, поэтому при её выборе манга не нужна
    final withManga = query.studio == null;
    // Сезон и студию API не фильтрует, их отсеиваем у себя, поэтому берём больше
    final limit = (query.season != null || query.studio != null) ? '25' : '12';

    final responses = await Future.wait([
      _client.getJson('/anime', _params(query, MediaType.anime, limit)),
      if (withManga)
        _client.getJson('/manga', _params(query, MediaType.manga, limit)),
    ]);

    final items = <MediaItem>[
      ..._toItems(responses[0], MediaType.anime),
      if (withManga) ..._toItems(responses[1], MediaType.manga),
    ].where((item) {
      if (query.season != null && item.season != query.season) return false;
      if (query.studio != null && item.studio != query.studio) return false;
      return true;
    }).toList();

    switch (query.sort) {
      case CatalogSort.popularity:
        items.sort((a, b) => a.popularity.compareTo(b.popularity));
      case CatalogSort.rating:
        items.sort((a, b) => b.rating.compareTo(a.rating));
      case CatalogSort.title:
        items.sort((a, b) => a.title.compareTo(b.title));
    }
    return items;
  }

  @override
  Future<String?> findCoverUrl(MediaItem item) {
    if (item.imageUrl != null) return Future.value(item.imageUrl);
    // Один и тот же тайтл ищем только один раз
    return _covers.putIfAbsent(item.id, () => _searchCover(item));
  }

  Future<String?> _searchCover(MediaItem item) async {
    try {
      final isManga = item.type == MediaType.manga;
      final json = await _client.getJson(isManga ? '/manga' : '/anime', {
        'q': item.title,
        'limit': '1',
        'sfw': 'true',
      });
      final found = parseMediaList(json);
      return found.isEmpty ? null : found.first.imageUrl;
    } on AppException {
      // Обложка не критична: при сбое остаётся градиент, а в следующий раз
      // попробуем снова
      _covers.remove(item.id);
      return null;
    }
  }

  @override
  void clearCache() => _client.clearCache();

  /// Параметры запроса Jikan из наших параметров каталога.
  Map<String, String> _params(CatalogQuery q, MediaType type, String limit) {
    final text = q.text.trim();
    final now = DateTime.now();
    final params = <String, String>{'limit': limit, 'sfw': 'true'};

    if (text.isNotEmpty) params['q'] = text;

    final genreId = kGenreIds[q.genre];
    if (genreId != null) params['genres'] = '$genreId';

    if (q.year != null) {
      params['start_date'] = '${q.year}-01-01';
      params['end_date'] = '${q.year}-12-31';
    } else if (q.category == CatalogCategory.newest) {
      params['start_date'] = '${now.year - 2}-01-01';
    }

    switch (q.category) {
      case CatalogCategory.airing:
        params['status'] = type == MediaType.anime ? 'airing' : 'publishing';
      case CatalogCategory.completed:
        params['status'] = 'complete';
      case CatalogCategory.popular:
      case CatalogCategory.newest:
        break;
    }

    switch (q.sort) {
      case CatalogSort.popularity:
        params['order_by'] = 'popularity';
        params['sort'] = 'asc';
      case CatalogSort.rating:
        params['order_by'] = 'score';
        params['sort'] = 'desc';
      case CatalogSort.title:
        params['order_by'] = 'title';
        params['sort'] = 'asc';
    }
    return params;
  }

  List<MediaItem> _toItems(Map<String, dynamic> json, MediaType type) {
    return [for (final dto in parseMediaList(json)) dto.toDomain(type)];
  }
}