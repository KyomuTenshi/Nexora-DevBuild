import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/utils/russian_plural.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/widgets/cached_data_banner.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';
import 'package:nexora/presentation/widgets/error_view.dart';
import 'package:nexora/presentation/widgets/skeleton.dart';
import 'catalog_grid.dart';
import 'catalog_labels.dart';
import 'catalog_search_bar.dart';
import 'category_chips.dart';
import 'filter_row.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  bool _filtersVisible = true;

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(catalogResultsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CatalogSearchBar(
              filtersVisible: _filtersVisible,
              onToggleFilters: () =>
                  setState(() => _filtersVisible = !_filtersVisible),
            ),
            const CachedDataBanner(),
            const CategoryChips(),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: _filtersVisible
                  ? const FilterRow()
                  : const SizedBox(width: double.infinity),
            ),
            const _ResultsInfoRow(),
            Expanded(
              child: results.when(
                // Пока грузятся новые результаты, держим старые на экране
                skipLoadingOnReload: true,
                loading: () => const CatalogSkeleton(),
                error: (error, _) => ErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(catalogResultsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return EmptyView(
                      icon: Icons.search_off_rounded,
                      title: 'Ничего не найдено',
                      message: 'Попробуйте изменить запрос или фильтры.',
                      actionLabel: 'Сбросить',
                      onAction: () =>
                          ref.read(catalogQueryProvider.notifier).reset(),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Сбрасываем кэш, иначе получим те же сохранённые данные
                      ref.read(mediaRepositoryProvider).clearCache();
                      ref.invalidate(catalogResultsProvider);
                      try {
                        await ref.read(catalogResultsProvider.future);
                      } catch (_) {
                        // Ошибку покажет сам экран (ErrorView с кнопкой «Повторить»)
                      }
                    },
                    child: CatalogGrid(items: items),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка «12 тайтлов» + выбор сортировки.
class _ResultsInfoRow extends ConsumerWidget {
  const _ResultsInfoRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final count = ref.watch(catalogResultsProvider).value?.length;
    final sort = ref.watch(catalogQueryProvider.select((q) => q.sort));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == null
                  ? ''
                  : '$count ${pluralRu(count, 'тайтл', 'тайтла', 'тайтлов')}',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ),
          PopupMenuButton<CatalogSort>(
            initialValue: sort,
            onSelected: ref.read(catalogQueryProvider.notifier).setSort,
            itemBuilder: (_) => [
              for (final s in CatalogSort.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sort.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }
}