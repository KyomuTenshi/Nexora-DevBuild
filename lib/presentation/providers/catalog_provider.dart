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

/// Результаты зависят от параметров: изменился query, и провайдер
/// автоматически пересчитался (запросил репозиторий заново).
final catalogResultsProvider = FutureProvider<List<MediaItem>>((ref) {
  final query = ref.watch(catalogQueryProvider);
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.searchCatalog(query);
});