import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/media_item.dart';

/// Хранит текущие параметры каталога. Экран только вызывает эти методы.
class CatalogQueryNotifier extends Notifier<CatalogQuery> {
  @override
  CatalogQuery build() => const CatalogQuery(); // начальное состояние

  void setText(String value) => state = state.copyWith(text: value);
  void setCategory(CatalogCategory value) =>
      state = state.copyWith(category: value);
  void setSort(CatalogSort value) => state = state.copyWith(sort: value);
  void setGenre(String? value) => state = state.copyWith(genre: () => value);
  void setYear(int? value) => state = state.copyWith(year: () => value);
  void setStudio(String? value) => state = state.copyWith(studio: () => value);
  void setSeason(String? value) => state = state.copyWith(season: () => value);

  void reset() => state = const CatalogQuery();
}

final catalogQueryProvider =
NotifierProvider<CatalogQueryNotifier, CatalogQuery>(
  CatalogQueryNotifier.new,
);

/// Только ПЕРВАЯ страница результатов обычным списком. Её читают подсказки
/// в строке поиска: им хватает пяти верхних строк, подгрузка не нужна.
/// Сам каталог берёт данные из [catalogFeedProvider].
final catalogResultsProvider = FutureProvider<List<MediaItem>>((ref) {
  final query = ref.watch(catalogQueryProvider);
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.searchCatalog(query);
});

/// Накопленный список каталога: всё, что уже подгружено, плюс служебные
/// признаки для подвала списка.
class CatalogFeed {
  const CatalogFeed({
    required this.items,
    required this.hasMore,
    this.nextPage = 1,
    this.loadingMore = false,
    this.moreError,
  });

  final List<MediaItem> items;

  /// Есть ли ещё страницы на сервере.
  final bool hasMore;

  /// Номер страницы, которую запросим следующей (первая, 0, уже загружена).
  final int nextPage;

  /// Идёт подгрузка очередной страницы.
  final bool loadingMore;

  /// Почему не удалась подгрузка (список при этом остаётся на экране).
  final Object? moreError;

  CatalogFeed copyWith({
    List<MediaItem>? items,
    bool? hasMore,
    int? nextPage,
    bool? loadingMore,
    Object? Function()? moreError,
  }) {
    return CatalogFeed(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? this.nextPage,
      loadingMore: loadingMore ?? this.loadingMore,
      moreError: moreError != null ? moreError() : this.moreError,
    );
  }
}

/// Постраничный каталог. build() грузит первую страницу и запускается заново
/// при каждой смене фильтров, loadMore() дописывает следующие страницы.
class CatalogFeedNotifier extends AsyncNotifier<CatalogFeed> {
  /// Номер «поколения» списка. build() увеличивает его при каждом новом
  /// запросе. Если подгрузка вернулась уже из другого поколения (человек
  /// успел сменить фильтр), её ответ устарел и выбрасывается.
  int _generation = 0;

  @override
  Future<CatalogFeed> build() async {
    _generation++;
    final query = ref.watch(catalogQueryProvider);
    final repository = ref.watch(mediaRepositoryProvider);

    final page = await repository.searchCatalogPage(query);
    return CatalogFeed(items: _unique(page.items), hasMore: page.hasMore);
  }

  /// Автоподгрузка при прокрутке. После ошибки молчит: иначе каждое движение
  /// пальца заново дёргало бы сервер. Повторить можно кнопкой (retryLoadMore).
  Future<void> loadMore() async {
    final feed = state.value;
    if (feed == null || feed.moreError != null) return;
    await _loadNext(feed);
  }

  /// Повтор по кнопке после ошибки подгрузки.
  Future<void> retryLoadMore() async {
    final feed = state.value;
    if (feed == null) return;
    await _loadNext(feed);
  }

  Future<void> _loadNext(CatalogFeed feed) async {
    // Пока список перезагружается (сменили фильтр), на экране ещё старые
    // данные. Подгружать к ним страницу нельзя: она затёрла бы новый список.
    if (state.isLoading || !feed.hasMore || feed.loadingMore) return;

    final generation = _generation;
    final query = ref.read(catalogQueryProvider);
    final repository = ref.read(mediaRepositoryProvider);

    // Список остаётся на экране: меняем только признак «идёт подгрузка»
    state = AsyncData(feed.copyWith(loadingMore: true, moreError: () => null));

    try {
      final page =
      await repository.searchCatalogPage(query, page: feed.nextPage);
      if (generation != _generation) return; // фильтры уже другие

      final current = state.requireValue;
      // Если на сервере за это время что-то сдвинулось, запись могла
      // прийти дважды. Дубли отбрасываем по id.
      final known = {for (final item in current.items) item.id};
      final fresh = [
        for (final item in _unique(page.items))
          if (!known.contains(item.id)) item,
      ];

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...fresh],
          hasMore: page.hasMore,
          nextPage: current.nextPage + 1,
          loadingMore: false,
        ),
      );
    } catch (error) {
      if (generation != _generation) return;
      state = AsyncData(
        state.requireValue.copyWith(
          loadingMore: false,
          moreError: () => error,
        ),
      );
    }
  }

  static List<MediaItem> _unique(List<MediaItem> items) {
    final seen = <int>{};
    return [
      for (final item in items)
        if (seen.add(item.id)) item,
    ];
  }
}

final catalogFeedProvider =
AsyncNotifierProvider<CatalogFeedNotifier, CatalogFeed>(
  CatalogFeedNotifier.new,
);