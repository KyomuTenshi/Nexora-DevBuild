import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/reader/reader_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:nexora/presentation/widgets/cover_art.dart';
import 'package:nexora/presentation/widgets/section_header.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';

/// «Продолжить чтение»: последняя манга со статусом «Читаю».
class ContinueReadingSection extends ConsumerWidget {
  const ContinueReadingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(libraryProvider)
        .values
        .where((e) =>
            e.status == LibraryStatus.inProgress &&
            e.item.type == MediaType.manga)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (entries.isEmpty) return const SizedBox.shrink();
    final entry = entries.first;
    final item = entry.item;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        SectionHeader(
          title: 'Продолжить чтение',
          onSeeAll: () => ref.read(shellTabProvider.notifier).setTab(2),
        ),
        GestureDetector(
          onTap: () => openReader(context, item, chapter: entry.next),
          onLongPress: () => openDetail(context, item),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CoverArt(seed: item.id),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.totalUnits == 0
                            ? 'Глава ${entry.next}'
                            : 'Глава ${entry.next} из ${item.totalUnits}',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ThinProgressBar(
                        value: entry.fraction,
                        color: AppColors.pink,
                        trackColor: scheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.pink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
