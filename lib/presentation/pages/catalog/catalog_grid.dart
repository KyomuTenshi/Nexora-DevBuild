import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/detail/detail_sheets.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/widgets/media_cover.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/rating_badge.dart';

/// Раскладка карточек: число колонок подстраивается под ширину экрана.
/// Общая для обеих сеток, чтобы они выглядели одинаково.
const _kCardGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  childAspectRatio: 0.60,
  crossAxisSpacing: 12,
  mainAxisSpacing: 16,
);

/// Простая сетка для готового списка без подгрузки (избранное, разделы профиля).
class CatalogGrid extends StatelessWidget {
  const CatalogGrid({super.key, required this.items});

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      // AlwaysScrollable нужен, чтобы pull-to-refresh работал и на коротком списке
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: _kCardGrid,
      itemCount: items.length,
      itemBuilder: (context, index) => CatalogCard(item: items[index]),
    );
  }
}

/// Сетка каталога с подгрузкой страниц. Карточки строятся лениво: в дереве
/// только те, что видны на экране и чуть выше и ниже.
class PagedCatalogGrid extends ConsumerWidget {
  const PagedCatalogGrid({super.key, required this.feed});

  final CatalogFeed feed;

  /// За сколько пикселей до конца списка начинаем грузить следующую страницу,
  /// чтобы человек обычно не упирался в «край».
  static const double _prefetchDistance = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = feed.items;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.axis == Axis.vertical &&
            metrics.extentAfter < _prefetchDistance) {
          // Повторные вызовы безопасны: loadMore сам проверяет, что уже грузит
          ref.read(catalogFeedProvider.notifier).loadMore();
        }
        return false; // пусть RefreshIndicator тоже получает уведомления
      },
      child: CustomScrollView(
        // AlwaysScrollable нужен, чтобы pull-to-refresh работал и на коротком списке
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverGrid(
              gridDelegate: _kCardGrid,
              delegate: SliverChildBuilderDelegate(
                (context, index) => CatalogCard(
                  // Ключ по id: при смене списка Flutter переиспользует
                  // уже построенные карточки тех же тайтлов
                  key: ValueKey(items[index].id),
                  item: items[index],
                ),
                childCount: items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _LoadMoreFooter(feed: feed)),
        ],
      ),
    );
  }
}

/// Подвал списка: индикатор, ошибка с «Повторить», «Показать ещё» или «Это всё».
class _LoadMoreFooter extends ConsumerWidget {
  const _LoadMoreFooter({required this.feed});

  final CatalogFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(catalogFeedProvider.notifier);

    final Widget child;
    if (feed.loadingMore) {
      child = const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    } else if (feed.moreError != null) {
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Не удалось загрузить следующую страницу',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          TextButton(
            onPressed: notifier.retryLoadMore,
            child: const Text('Повторить'),
          ),
        ],
      );
    } else if (feed.hasMore) {
      // Кнопка нужна на случай, когда список не прокрутить (короткий или
      // широкий экран): автоподгрузка срабатывает только от прокрутки
      child = OutlinedButton(
        onPressed: notifier.loadMore,
        child: const Text('Показать ещё'),
      );
    } else {
      child = Text('Это всё', style: TextStyle(color: scheme.onSurfaceVariant));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Center(child: child),
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
              child: MediaCover(
                item: item,
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
