import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

/// Похожие тайтлы: тот же тип и общие жанры, чем больше общих, тем выше.
final similarProvider =
    FutureProvider.family<List<MediaItem>, MediaItem>((ref, item) async {
  final repository = ref.watch(mediaRepositoryProvider);
  final all = await repository.searchCatalog(const CatalogQuery());

  int shared(MediaItem other) =>
      other.genres.where(item.genres.contains).length;

  final result = all
      .where((o) => o.id != item.id && o.type == item.type && shared(o) > 0)
      .toList()
    ..sort((a, b) => shared(b).compareTo(shared(a)));
  return result.take(6).toList();
});

/// Подборка «Для вас» по любимым жанрам из профиля.
/// Следим только за списком жанров, а не за всем профилем.
final recommendedProvider = FutureProvider<List<MediaItem>>((ref) async {
  final genres = ref.watch(profileProvider.select((p) => p.genres.join('|')));
  final repository = ref.watch(mediaRepositoryProvider);
  final all = await repository.searchCatalog(
    const CatalogQuery(sort: CatalogSort.rating),
  );
  if (genres.isEmpty) return all.take(8).toList();

  final wanted = genres.split('|');
  return all.where((o) => o.genres.any(wanted.contains)).take(8).toList();
});
