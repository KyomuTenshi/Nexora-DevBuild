import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/showcase.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/profile/favorites_page.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_layout_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/ratings_provider.dart';
import 'package:nexora/presentation/widgets/media_cover.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';

/// Блок на странице профиля: скруглённая карточка с заголовком.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Нужная витрина по её типу.
class ShowcaseBlock extends StatelessWidget {
  const ShowcaseBlock({super.key, required this.type});

  final ShowcaseType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      ShowcaseType.favoriteTitle => const _FavoriteTitleBlock(),
      ShowcaseType.favorites => const _FavoritesBlock(),
      ShowcaseType.nowWatching => const _NowWatchingBlock(),
      ShowcaseType.stats => const _StatsBlock(),
      ShowcaseType.ratings => const _RatingsBlock(),
      ShowcaseType.genres => const _GenresBlock(),
    };
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

const _chevron = Icon(Icons.chevron_right_rounded);

// ---------------------------------------------------------------- любимый тайтл

class _FavoriteTitleBlock extends ConsumerWidget {
  const _FavoriteTitleBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final id = ref.watch(profileLayoutProvider.select((l) => l.favoriteTitleId));
    final item = ref.watch(favoritesProvider)[id];
    final myRating = item == null ? null : ref.watch(ratingsProvider)[item.id];

    return ProfileCard(
      title: 'Любимый тайтл',
      child: item == null
          ? const _Hint(
        'Выберите любимый тайтл в редакторе профиля. Он берётся из избранного.',
      )
          : InkWell(
        onTap: () => openDetail(context, item),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: AspectRatio(
                aspectRatio: 0.72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: MediaCover(item: item),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.type.label} · ${item.year ?? '—'}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 18, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        myRating == null
                            ? 'Вы ещё не оценили'
                            : 'Ваша оценка: $myRating из 5',
                        style:
                        const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- любимое

class _FavoritesBlock extends ConsumerWidget {
  const _FavoritesBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final chosen = ref.watch(profileLayoutProvider.select((l) => l.favoriteIds));

    // Выбранные по порядку; если ничего не выбрано, первые из избранного
    var items = [
      for (final id in chosen)
        if (favorites[id] != null) favorites[id]!,
    ];
    if (items.isEmpty) items = favorites.values.take(kMaxFavorites).toList();

    return ProfileCard(
      title: 'Любимое аниме и манга',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const FavoritesPage()),
      ),
      trailing: _chevron,
      child: items.isEmpty
          ? const _Hint(
        'Нажмите на сердечко на странице тайтла, и он появится здесь.',
      )
          : Row(
        children: [
          for (var i = 0; i < kMaxFavorites; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: i < items.length
                  ? GestureDetector(
                onTap: () => openDetail(context, items[i]),
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: MediaCover(item: items[i]),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- сейчас

class _NowWatchingBlock extends ConsumerWidget {
  const _NowWatchingBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final entries = ref
        .watch(libraryProvider)
        .values
        .where((e) => e.status == LibraryStatus.inProgress)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final shown = entries.take(3).toList();

    return ProfileCard(
      title: 'Сейчас смотрю и читаю',
      child: shown.isEmpty
          ? const _Hint('Начните смотреть или читать, и тайтл появится здесь.')
          : Column(
        children: [
          for (final e in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => openDetail(context, e.item),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 68,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: MediaCover(item: e.item),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${e.item.type.label} · ${e.progress} / '
                                '${e.item.totalUnits == 0 ? '?' : e.item.totalUnits} '
                                '${e.item.type.unitShort}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ThinProgressBar(
                            value: e.fraction,
                            color: scheme.primary,
                            trackColor: scheme.surfaceContainerHighest,
                            height: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- статистика

/// Статистика списком строк, как в профиле Steam: слева название,
/// справа число. Набор строк выбирается в редакторе витрин.
class _StatsBlock extends ConsumerWidget {
  const _StatsBlock();

  String _value(
      StatKey key,
      List<LibraryEntry> entries,
      int favorites,
      Map<int, int> ratings,
      ) {
    return switch (key) {
      StatKey.inLists => '${entries.length}',
      StatKey.completed =>
      '${entries.where((e) => e.status == LibraryStatus.completed).length}',
      StatKey.favorites => '$favorites',
      StatKey.rated => '${ratings.length}',
      StatKey.anime =>
      '${entries.where((e) => e.item.type == MediaType.anime).length}',
      StatKey.manga =>
      '${entries.where((e) => e.item.type == MediaType.manga).length}',
      StatKey.average => ratings.isEmpty
          ? '—'
          : (ratings.values.fold<int>(0, (a, b) => a + b) / ratings.length)
          .toStringAsFixed(1),
    };
  }

  IconData _icon(StatKey key) => switch (key) {
    StatKey.inLists => Icons.bookmark_rounded,
    StatKey.completed => Icons.check_circle_rounded,
    StatKey.favorites => Icons.favorite_rounded,
    StatKey.rated => Icons.star_rounded,
    StatKey.anime => Icons.tv_rounded,
    StatKey.manga => Icons.menu_book_rounded,
    StatKey.average => Icons.insights_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final keys = ref.watch(profileLayoutProvider.select((l) => l.statKeys));
    final entries = ref.watch(libraryProvider).values.toList();
    final favorites = ref.watch(favoritesProvider).length;
    final ratings = ref.watch(ratingsProvider);

    return ProfileCard(
      title: 'Статистика',
      child: keys.isEmpty
          ? const _Hint('Выберите показатели в редакторе витрин.')
          : Column(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _icon(keys[i]),
                    size: 20,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      keys[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    _value(keys[i], entries, favorites, ratings),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- оценки

class _RatingsBlock extends ConsumerWidget {
  const _RatingsBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ratings = ref.watch(ratingsProvider);

    final counts = {for (var s = 1; s <= 5; s++) s: 0};
    for (final v in ratings.values) {
      if (counts.containsKey(v)) counts[v] = counts[v]! + 1;
    }
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);

    return ProfileCard(
      title: 'Распределение оценок',
      trailing: Text(
        'Всего: ${ratings.length}',
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      child: ratings.isEmpty
          ? const _Hint('Оцените тайтлы звёздами, и здесь появится график.')
          : Column(
        children: [
          for (var s = 5; s >= 1; s--)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$s ★',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ThinProgressBar(
                      value: maxCount == 0 ? 0 : counts[s]! / maxCount,
                      color: scheme.primary,
                      trackColor: scheme.surfaceContainerHighest,
                      height: 8,
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${counts[s]}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- жанры

class _GenresBlock extends ConsumerWidget {
  const _GenresBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(profileProvider.select((p) => p.genres));

    return ProfileCard(
      title: 'Любимые жанры',
      child: genres.isEmpty
          ? const _Hint('Выберите жанры в разделе «Основное» редактора.')
          : Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final g in genres) Chip(label: Text(g))],
      ),
    );
  }
}