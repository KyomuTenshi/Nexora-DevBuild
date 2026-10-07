import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/detail/detail_sheets.dart';
import 'package:nexora/presentation/pages/player/watch_page.dart';
import 'package:nexora/presentation/pages/reader/reader_page.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/widgets/cover_art.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';

/// Карточка в сетке библиотеки: обложка, прогресс, «Новая серия», сердечко.
class LibraryCard extends ConsumerWidget {
  const LibraryCard({super.key, required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final item = entry.item;
    final isFavorite =
        ref.watch(favoritesProvider.select((s) => s.contains(item.id)));
    final hasNew = item.type == MediaType.anime &&
        item.status == AiringStatus.airing &&
        entry.status == LibraryStatus.inProgress;
    final completed = entry.status == LibraryStatus.completed;

    return GestureDetector(
      onTap: () => openDetail(context, item),
      onLongPress: () => showEntryActions(context, entry),
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
                    if (hasNew)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Новая серия',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (isFavorite)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 15,
                            color: AppColors.pink,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: ThinProgressBar(
                        value: entry.fraction,
                        color: completed ? AppColors.success : scheme.primary,
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
          Text(
            item.totalUnits == 0
                ? '${entry.progress}'
                : '${entry.progress} / ${item.totalUnits}',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Быстрые действия по долгому нажатию на карточку.
Future<void> showEntryActions(BuildContext context, LibraryEntry entry) {
  final item = entry.item;
  final isAnime = item.type == MediaType.anime;

  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;

      return Consumer(
        builder: (_, ref, _) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  isAnime ? Icons.play_arrow_rounded : Icons.menu_book_rounded,
                ),
                title: Text(
                  isAnime
                      ? 'Смотреть серию ${entry.next}'
                      : 'Читать главу ${entry.next}',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  if (isAnime) {
                    openWatch(context, item, episode: entry.next);
                  } else {
                    openReader(context, item, chapter: entry.next);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz_rounded),
                title: const Text('Перенести в другой список'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showStatusSheet(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border_rounded),
                title: const Text('В избранное / из избранного'),
                onTap: () {
                  ref.read(favoritesProvider.notifier).toggle(item.id);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
                title: Text(
                  'Убрать из библиотеки',
                  style: TextStyle(color: scheme.error),
                ),
                onTap: () {
                  ref.read(libraryProvider.notifier).remove(item.id);
                  Navigator.of(sheetContext).pop();
                  showInfo(context, '«${item.title}» убран из библиотеки');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
