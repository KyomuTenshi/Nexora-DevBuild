import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/utils/russian_plural.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';
import 'library_card.dart';
import 'library_labels.dart';

enum _LibrarySort { recent, title, progress }

extension on _LibrarySort {
  String get label => switch (this) {
        _LibrarySort.recent => 'Недавние сверху',
        _LibrarySort.title => 'По названию',
        _LibrarySort.progress => 'По прогрессу',
      };
}

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  MediaType _type = MediaType.anime;
  LibraryStatus _status = LibraryStatus.inProgress;
  _LibrarySort _sort = _LibrarySort.recent;
  bool _searching = false;
  String _search = '';

  // Контроллер нужен, чтобы очищать текст в поле вместе с _search
  final _searchController = TextEditingController();

  static const _statusOrder = [
    LibraryStatus.inProgress,
    LibraryStatus.paused,
    LibraryStatus.completed,
    LibraryStatus.planned,
    LibraryStatus.dropped,
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetSearch() {
    _searchController.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final ofType = ref
        .watch(libraryProvider)
        .values
        .where((e) => e.item.type == _type)
        .toList();
    int count(LibraryStatus s) => ofType.where((e) => e.status == s).length;

    final query = _search.trim().toLowerCase();
    final shown = ofType
        .where((e) =>
            e.status == _status &&
            (query.isEmpty || e.item.title.toLowerCase().contains(query)))
        .toList();
    switch (_sort) {
      case _LibrarySort.recent:
        shown.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _LibrarySort.title:
        shown.sort((a, b) => a.item.title.compareTo(b.item.title));
      case _LibrarySort.progress:
        shown.sort((a, b) => b.fraction.compareTo(a.fraction));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(scheme),
            _buildSegments(scheme),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusOrder.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final status = _statusOrder[i];
                  final selected = status == _status;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _status = status),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.15)
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? scheme.primary : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: Text(
                        '${status.labelFor(_type)} ${count(status)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${shown.length} ${pluralRu(shown.length, 'тайтл', 'тайтла', 'тайтлов')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PopupMenuButton<_LibrarySort>(
                    initialValue: _sort,
                    onSelected: (v) => setState(() => _sort = v),
                    itemBuilder: (_) => [
                      for (final s in _LibrarySort.values)
                        PopupMenuItem(value: s, child: Text(s.label)),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _sort.label,
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
            ),
            Expanded(
              child: shown.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 140,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.54,
                      ),
                      itemCount: shown.length,
                      itemBuilder: (context, i) =>
                          LibraryCard(entry: shown[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    if (_search.isNotEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        title: 'Ничего не найдено',
        message: 'По запросу «$_search» ничего нет в этом списке.',
        actionLabel: 'Сбросить поиск',
        onAction: _resetSearch,
      );
    }
    return EmptyView(
      icon: Icons.collections_bookmark_outlined,
      title: 'Здесь пока пусто',
      message: 'Добавьте тайтл в список в каталоге или на странице тайтла.',
      actionLabel: 'Открыть каталог',
      onAction: () => ref.read(shellTabProvider.notifier).setTab(1),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: _searching
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Поиск в библиотеке',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: _resetSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searching = false;
                      _search = '';
                    });
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            )
          : Row(
              children: [
                const Expanded(
                  child: Text(
                    'Библиотека',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _searching = true),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
    );
  }

  Widget _buildSegments(ColorScheme scheme) {
    Widget segment(String label, MediaType type) {
      final selected = _type == type;
      return Expanded(
        child: Material(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _type = type;
              _status = LibraryStatus.inProgress;
            }),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          segment('Аниме', MediaType.anime),
          segment('Манга', MediaType.manga),
        ],
      ),
    );
  }
}
