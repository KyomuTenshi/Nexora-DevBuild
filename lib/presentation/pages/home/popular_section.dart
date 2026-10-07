import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/similar_provider.dart';
import 'package:nexora/presentation/widgets/cover_art.dart';
import 'package:nexora/presentation/widgets/rating_badge.dart';
import 'package:nexora/presentation/widgets/section_header.dart';

/// Горизонтальная лента постеров. Используется для «Популярно» и «Для вас».
class PopularSection extends StatelessWidget {
  const PopularSection({super.key, required this.items});

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 244,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _PosterCard(item: items[i]),
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = item.year != null
        ? '${item.year} · ${item.genres.isEmpty ? item.type.name : item.genres.first}'
        : (item.genres.isEmpty ? '' : item.genres.first);

    return GestureDetector(
      onTap: () => openDetail(context, item),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CoverArt(
                  seed: item.id,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 8,
                        top: 8,
                        child: RatingBadge(rating: item.rating),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              info,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Для вас»: тайтлы по любимым жанрам из профиля, без уже добавленных в список.
class RecommendedSection extends ConsumerWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommended = ref.watch(recommendedProvider);
    final library = ref.watch(libraryProvider);

    return recommended.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        final fresh = items.where((i) => !library.containsKey(i.id)).toList();
        if (fresh.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            const SectionHeader(title: 'Для вас'),
            PopularSection(items: fresh),
          ],
        );
      },
    );
  }
}
