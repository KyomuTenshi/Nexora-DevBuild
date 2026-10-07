import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

/// Похожие тайтлы: просим у API тайтлы первого известного жанра, оставляем
/// тот же тип, чем больше общих жанров, тем выше в списке.
final similarProvider =
FutureProvider.family<List<MediaItem>, MediaItem>((ref, item) async {
  final repository = ref.watch(mediaRepositoryProvider);

  // Фильтровать API умеет только по жанрам из нашего списка kGenreIds
  final genre = item.genres.where(kGenreIds.containsKey).firstOrNull;
  final all = await repository.searchCatalog(
    CatalogQuery(genre: genre, sort: CatalogSort.rating),
  );

  int shared(MediaItem other) =>
      other.genres.where(item.genres.contains).length;

  final result = all
      .where((o) => o.id != item.id && o.type == item.type)
      .toList()
    ..sort((a, b) => shared(b).compareTo(shared(a)));
  return result.take(6).toList();
});

/// Подборка «Для вас» по любимым жанрам из профиля.
/// Следим только за списком жанров, а не за всем профилем.
final recommendedProvider = FutureProvider<List<MediaItem>>((ref) async {
  final genres = ref.watch(profileProvider.select((p) => p.genres.join('|')));
  final repository = ref.watch(mediaRepositoryProvider);

  if (genres.isEmpty) {
    final top = await repository.searchCatalog(
      const CatalogQuery(sort: CatalogSort.rating),
    );
    return top.take(8).toList();
  }

  // По запросу на каждый из первых двух жанров, потом склеиваем без повторов
  final wanted = genres.split('|').take(2);
  final lists = await Future.wait([
    for (final g in wanted)
      repository.searchCatalog(CatalogQuery(genre: g, sort: CatalogSort.rating)),
  ]);
  final merged = {for (final list in lists) for (final i in list) i.id: i}
      .values
      .toList()
    ..sort((a, b) => b.rating.compareTo(a.rating));
  return merged.take(8).toList();
});