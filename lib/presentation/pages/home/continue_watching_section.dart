import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/player/watch_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:nexora/presentation/widgets/cover_art.dart';
import 'package:nexora/presentation/widgets/section_header.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';

/// «Продолжить просмотр» собирается из библиотеки: аниме со статусом «Смотрю»,
/// самое свежее слева. Тап по карточке запускает следующую серию.
class ContinueWatchingSection extends ConsumerWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(libraryProvider)
        .values
        .where((e) =>
            e.status == LibraryStatus.inProgress &&
            e.item.type == MediaType.anime)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (entries.isEmpty) return const SizedBox.shrink();
    final shown = entries.take(10).toList();

    return Column(
      children: [
        SectionHeader(
          title: 'Продолжить просмотр',
          onSeeAll: () => ref.read(shellTabProvider.notifier).setTab(2),
        ),
        SizedBox(
          height: 204,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _WatchCard(entry: shown[i]),
          ),
        ),
      ],
    );
  }
}

class _WatchCard extends StatelessWidget {
  const _WatchCard({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = entry.item;
    final total = item.totalUnits;

    return GestureDetector(
      onTap: () => openWatch(context, item, episode: entry.next),
      onLongPress: () => openDetail(context, item),
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: CoverArt(
                  seed: item.id,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: ThinProgressBar(
                          value: entry.fraction,
                          color: scheme.primary,
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              total == 0
                  ? 'Серия ${entry.next}'
                  : 'Серия ${entry.next} из $total',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
