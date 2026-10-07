import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/media_item.dart';

/// Все тайтлы каталога без фильтров. Нужен профилю, чтобы по id из избранного
/// найти сами тайтлы.
final allItemsProvider = FutureProvider<List<MediaItem>>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.searchCatalog(const CatalogQuery());
});
