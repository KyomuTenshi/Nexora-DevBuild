import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/pages/catalog/catalog_grid.dart';
import 'package:nexora/presentation/providers/all_items_provider.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';
import 'package:nexora/presentation/widgets/error_view.dart';

/// Все избранные тайтлы пользователя.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    final all = ref.watch(allItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: all.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorView(
          onRetry: () => ref.invalidate(allItemsProvider),
        ),
        data: (items) {
          final favorites = items.where((i) => ids.contains(i.id)).toList();
          if (favorites.isEmpty) {
            return const EmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'Пока ничего нет',
              message: 'Нажмите на сердечко на странице тайтла.',
            );
          }
          return CatalogGrid(items: favorites);
        },
      ),
    );
  }
}
