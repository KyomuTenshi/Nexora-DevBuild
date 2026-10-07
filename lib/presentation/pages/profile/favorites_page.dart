import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/pages/catalog/catalog_grid.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';

/// Все избранные тайтлы пользователя.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: favorites.isEmpty
          ? const EmptyView(
        icon: Icons.favorite_border_rounded,
        title: 'Пока ничего нет',
        message: 'Нажмите на сердечко на странице тайтла.',
      )
          : CatalogGrid(items: favorites),
    );
  }
}