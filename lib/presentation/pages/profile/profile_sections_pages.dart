import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/catalog/catalog_grid.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/reviews_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';

/// Всё аниме (или вся манга) из вашей библиотеки, свежие сверху.
class ProfileTitlesPage extends ConsumerWidget {
  const ProfileTitlesPage({super.key, required this.type});

  final MediaType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref
        .watch(libraryProvider)
        .values
        .where((e) => e.item.type == type)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final isAnime = type == MediaType.anime;

    return Scaffold(
      appBar: AppBar(title: Text(isAnime ? 'Моё аниме' : 'Моя манга')),
      body: entries.isEmpty
          ? EmptyView(
        icon: isAnime
            ? Icons.movie_outlined
            : Icons.menu_book_outlined,
        title: 'Пока пусто',
        message: 'Добавьте тайтлы в библиотеку, и они появятся здесь.',
      )
          : CatalogGrid(items: [for (final e in entries) e.item]),
    );
  }
}

/// Мои отзывы. Пока они живут только до закрытия приложения: постоянное
/// хранение придёт вместе с сервером.
class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(reviewsProvider);
    final library = ref.watch(libraryProvider);
    final favorites = ref.watch(favoritesProvider);

    final mine = <(String, Review)>[
      for (final entry in all.entries)
        for (final r in entry.value)
          if (r.mine)
            (
            library[entry.key]?.item.title ??
                favorites[entry.key]?.title ??
                'Тайтл №${entry.key}',
            r,
            ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Мои отзывы')),
      body: mine.isEmpty
          ? const EmptyView(
        icon: Icons.rate_review_outlined,
        title: 'Отзывов пока нет',
        message: 'Напишите отзыв на странице тайтла, и он появится здесь.',
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mine.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (title, review) = mine[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review.rating == 0
                      ? 'Без оценки'
                      : '★' * review.rating,
                  style: TextStyle(color: scheme.primary),
                ),
                const SizedBox(height: 6),
                Text(review.text),
              ],
            ),
          );
        },
      ),
    );
  }
}