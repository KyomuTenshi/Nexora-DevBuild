import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/widgets/search_box.dart';

/// Поиск каталога: то же поле с выпадающей панелью, что и на Главной,
/// плюс кнопка фильтров справа.
class CatalogSearchBar extends ConsumerWidget {
  const CatalogSearchBar({
    super.key,
    required this.filtersVisible,
    required this.onToggleFilters,
  });

  final bool filtersVisible;
  final VoidCallback onToggleFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final hasFilters =
    ref.watch(catalogQueryProvider.select((q) => q.hasFilters));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SearchBox(
        height: 52,
        radius: 16,
        trailing: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Material(
            color: filtersVisible
                ? scheme.primary.withValues(alpha: 0.2)
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onToggleFilters,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Center(
                  child: Badge(
                    isLabelVisible: hasFilters,
                    smallSize: 8,
                    child: const Icon(Icons.filter_alt_outlined, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}