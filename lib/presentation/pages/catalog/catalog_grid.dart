import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/detail/detail_sheets.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/widgets/cover_art.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/rating_badge.dart';

/// Сетка карточек. Число колонок подстраивается под ширину экрана.
class CatalogGrid extends StatelessWidget {
  const CatalogGrid({super.key, required this.items});

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // AlwaysScrollable нужен, чтобы pull-to-refresh работал и на коротком списке
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 0.60,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => CatalogCard(item: items[index]),
    );
  }
}

/// Карточка тайтла: тап открывает страницу, закладка меняет список.
class CatalogCard extends ConsumerWidget {
  const CatalogCard({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final inLibrary = ref.watch(
      libraryProvider.select((m) => m.containsKey(item.id)),
    );
    final info = '${unitsLabel(item)} · ${item.studio ?? item.type.label}';

    return GestureDetector(
      onTap: () => openDetail(context, item),
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
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => showStatusSheet(context, item),
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              inLibrary
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              size: 20,
                              color: inLibrary ? scheme.primary : Colors.white,
                            ),
                          ),
                        ),
                      ),
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
          const SizedBox(height: 2),
          Text(
            info,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
