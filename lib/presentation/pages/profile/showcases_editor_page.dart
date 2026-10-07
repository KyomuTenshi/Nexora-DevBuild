import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/showcase.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/profile_layout_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

IconData _iconOf(ShowcaseType t) => switch (t) {
  ShowcaseType.favoriteTitle => Icons.star_rounded,
  ShowcaseType.favorites => Icons.favorite_rounded,
  ShowcaseType.nowWatching => Icons.play_circle_rounded,
  ShowcaseType.stats => Icons.bar_chart_rounded,
  ShowcaseType.ratings => Icons.stacked_bar_chart_rounded,
  ShowcaseType.genres => Icons.category_rounded,
};

/// Редактор витрин: как «Featured Showcases» в Steam. Порядок, видимость,
/// настройка содержимого и открытие новых блоков за очки.
class ShowcasesEditorPage extends ConsumerWidget {
  const ShowcasesEditorPage({super.key});

  Future<void> _buy(
      BuildContext context,
      WidgetRef ref,
      ShowcaseType type,
      ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Открыть «${type.title}»?'),
        content: Text(
          'Спишется ${formatNumber(type.price)} очков. '
              'Витрина останется у вас навсегда.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final bought = ref.read(profileLayoutProvider.notifier).buy(type);
    showInfo(
      context,
      bought ? 'Витрина «${type.title}» открыта' : 'Не хватает очков',
    );
  }

  void _configure(BuildContext context, ShowcaseType type) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => switch (type) {
        ShowcaseType.favoriteTitle => const _FavoriteTitlePicker(),
        ShowcaseType.favorites => const _FavoritesPicker(),
        ShowcaseType.stats => const _StatsPicker(),
        _ => const SizedBox.shrink(),
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final layout = ref.watch(profileLayoutProvider);
    final points = ref.watch(profileProvider.select((p) => p.points));
    final notifier = ref.read(profileLayoutProvider.notifier);

    final owned = [
      for (final t in layout.order)
        if (layout.owned.contains(t)) t,
    ];
    final locked = [
      for (final t in layout.order)
        if (!layout.owned.contains(t)) t,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Витрины')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Ваши очки: ${formatNumber(points)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Мои витрины',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Перетащите за ручку, чтобы поменять порядок на странице профиля.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: notifier.reorderOwned,
            children: [
              for (var i = 0; i < owned.length; i++)
                Padding(
                  key: ValueKey(owned[i]),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                      child: Row(
                        children: [
                          Icon(_iconOf(owned[i]), color: scheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  owned[i].title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (owned[i].configurable)
                                  GestureDetector(
                                    onTap: () => _configure(context, owned[i]),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Настроить',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: scheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Switch(
                            value: layout.isVisible(owned[i]),
                            onChanged: (v) => notifier.setVisible(owned[i], v),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.drag_handle_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (locked.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Открыть за очки',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final t in locked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          _iconOf(t),
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                t.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () => _buy(context, ref, t),
                          child: Text(formatNumber(t.price)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Лист с заголовком и содержимым, не выше 70% экрана.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTitlePicker extends ConsumerWidget {
  const _FavoriteTitlePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(favoritesProvider).values.toList();
    final current =
    ref.watch(profileLayoutProvider.select((l) => l.favoriteTitleId));

    return _SheetFrame(
      title: 'Любимый тайтл',
      subtitle: items.isEmpty
          ? 'Сначала добавьте тайтлы в избранное.'
          : 'Нажмите на тайтл. Повторное нажатие снимает выбор.',
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final item in items)
            ListTile(
              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(item.type.label),
              trailing: item.id == current
                  ? Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary,
              )
                  : null,
              onTap: () => ref.read(profileLayoutProvider.notifier).edit(
                    (l) => l.copyWith(
                  favoriteTitleId: item.id == current ? 0 : item.id,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FavoritesPicker extends ConsumerWidget {
  const _FavoritesPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(favoritesProvider).values.toList();
    final chosen =
    ref.watch(profileLayoutProvider.select((l) => l.favoriteIds));

    return _SheetFrame(
      title: 'Любимое аниме и манга',
      subtitle: items.isEmpty
          ? 'Сначала добавьте тайтлы в избранное.'
          : 'Выберите до $kMaxFavorites. Без выбора показываются первые из избранного.',
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final item in items)
            CheckboxListTile(
              title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(item.type.label),
              value: chosen.contains(item.id),
              onChanged: (v) {
                final next = [...chosen];
                if (v == true) {
                  if (next.length >= kMaxFavorites) {
                    showInfo(context, 'Можно выбрать не больше $kMaxFavorites');
                    return;
                  }
                  next.add(item.id);
                } else {
                  next.remove(item.id);
                }
                ref
                    .read(profileLayoutProvider.notifier)
                    .edit((l) => l.copyWith(favoriteIds: next));
              },
            ),
        ],
      ),
    );
  }
}

class _StatsPicker extends ConsumerWidget {
  const _StatsPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = ref.watch(profileLayoutProvider.select((l) => l.statKeys));

    return _SheetFrame(
      title: 'Статистика',
      subtitle: 'Выберите от 1 до $kMaxStats чисел.',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in StatKey.values)
              FilterChip(
                label: Text(key.label),
                selected: chosen.contains(key),
                onSelected: (v) {
                  final next = [...chosen];
                  if (v) {
                    if (next.length >= kMaxStats) {
                      showInfo(context, 'Можно выбрать не больше $kMaxStats');
                      return;
                    }
                    next.add(key);
                  } else {
                    if (next.length <= 1) return;
                    next.remove(key);
                  }
                  ref
                      .read(profileLayoutProvider.notifier)
                      .edit((l) => l.copyWith(statKeys: next));
                },
              ),
          ],
        ),
      ),
    );
  }
}