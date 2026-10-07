import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/dto/kitsu_dto.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/home_feed.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/media_repository.dart';

/// Репозиторий поверх Kitsu (REST API, формат JSON:API). Экраны о нём не
/// знают: они работают с интерфейсом [MediaRepository].
class KitsuMediaRepository implements MediaRepository {
  KitsuMediaRepository(this._client);

  final ApiClient _client;
  final Map<int, Future<String?>> _covers = {};

  /// Kitsu отдаёт не больше 20 записей за запрос.
  static const _pageSize = '20';

  @override
  Future<HomeFeed> getHomeFeed() async {
    // Два независимых запроса идут параллельно
    final responses = await Future.wait([
      _client.getJson('/anime', {
        'filter[status]': 'current',
        'sort': 'popularityRank',
        'page[limit]': '5',
        'include': 'categories',
      }),
      _client.getJson('/anime', {
        'sort': 'popularityRank',
        'page[limit]': '12',
        'include': 'categories',
      }),
    ]);

    final airing = _toItems(responses[0], MediaType.anime);
    final popular = _toItems(responses[1], MediaType.anime);

    // Если «сейчас в эфире» пусто, карусель строим из популярного
    final featuredSource =
    airing.isNotEmpty ? airing : popular.take(3).toList();
    final featured = [
      for (final item in featuredSource)
        FeaturedBanner(
          item: item,
          badge: item.status == AiringStatus.airing
              ? 'Сейчас в эфире'
              : 'Популярное',
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
    // Студии в основном ответе Kitsu нет, поэтому фильтр студии не применяется.
    final anime = _list(query, MediaType.anime);
    // Если с мангой что-то не так (сервер ответил ошибкой), показываем аниме.
    // Сбой сети по-прежнему считается ошибкой всего экрана.
    final manga = _list(query, MediaType.manga).catchError(
          (Object _) => <MediaItem>[],
      test: (error) => error is ServerException,
    );

    final results = await Future.wait([anime, manga]);
    final items = [...results[0], ...results[1]];

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

  /// Один запрос к /anime или /manga плюс фильтры, которые удобнее применить
  /// у себя (год, сезон, статус). Они же служат страховкой, если сервер не
  /// принял какой-то из «необязательных» параметров.
  Future<List<MediaItem>> _list(CatalogQuery q, MediaType type) async {
    final path = type == MediaType.anime ? '/anime' : '/manga';
    final params = _params(q, type);

    Map<String, dynamic> json;
    try {
      json = await _client.getJson(path, params);
    } on ServerException catch (e) {
      // Ошибка 4xx: пробуем ещё раз без необязательных фильтров
      final fallback = Map.of(params)
        ..remove('filter[year]')
        ..remove('filter[status]');
      final badRequest = e.statusCode >= 400 && e.statusCode < 500;
      if (!badRequest || fallback.length == params.length) rethrow;
      json = await _client.getJson(path, fallback);
    }

    final now = DateTime.now().year;
    return _toItems(json, type).where((item) {
      if (q.year != null && item.year != q.year) return false;
      if (q.season != null && item.season != q.season) return false;
      switch (q.category) {
        case CatalogCategory.popular:
          return true;
        case CatalogCategory.newest:
          return q.year != null || (item.year ?? 0) >= now - 2;
        case CatalogCategory.airing:
          return item.status == AiringStatus.airing;
        case CatalogCategory.completed:
          return item.status == AiringStatus.finished;
      }
    }).toList();
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
        'filter[text]': item.title,
        'page[limit]': '1',
      });
      final found = parseKitsuList(json);
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

  /// Параметры запроса Kitsu из наших параметров каталога.
  Map<String, String> _params(CatalogQuery q, MediaType type) {
    final text = q.text.trim();
    final now = DateTime.now().year;
    final isAnime = type == MediaType.anime;
    final params = <String, String>{
      'page[limit]': _pageSize,
      'include': 'categories',
    };

    if (text.isNotEmpty) params['filter[text]'] = text;

    final slug = kGenreSlugs[q.genre];
    if (slug != null) params['filter[categories]'] = slug;

    // Для текстового поиска порядок задаёт релевантность, сортировку не шлём
    if (text.isEmpty) {
      params['sort'] = q.sort == CatalogSort.rating
          ? '-averageRating'
          : 'popularityRank';
    }

    // Год и «новинки» на сервере фильтруем только у аниме
    if (isAnime) {
      if (q.year != null) {
        params['filter[year]'] = '${q.year}';
      } else if (q.category == CatalogCategory.newest) {
        params['filter[year]'] = '${now - 2}..$now';
      }
    }

    switch (q.category) {
      case CatalogCategory.airing:
        params['filter[status]'] = 'current';
      case CatalogCategory.completed:
        params['filter[status]'] = 'finished';
      case CatalogCategory.popular:
      case CatalogCategory.newest:
        break;
    }
    return params;
  }

  List<MediaItem> _toItems(Map<String, dynamic> json, MediaType type) {
    return [for (final dto in parseKitsuList(json)) dto.toDomain(type)];
  }
}