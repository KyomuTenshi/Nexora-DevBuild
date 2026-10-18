import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_unit.dart';
import 'package:nexora/presentation/pages/reader/manga_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/units_provider.dart';

import 'package:go_router/go_router.dart';
import 'package:nexora/core/router/app_router.dart';

/// Открывает читалку на нужной главе.
void openReader(BuildContext context, MediaItem item, {required int chapter}) {
  context.pushNamed(
    AppRoute.read,
    pathParameters: {'id': '${item.id}', 'chapter': '$chapter'},
    extra: item,
  );
}

class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.item, required this.chapter});

  final MediaItem item;
  final int chapter;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late int _chapter;
  int _page = 0;
  bool _barsVisible = true;
  bool _horizontal = false; // false: лента вниз, true: листаем страницы
  bool _dark = false; // тёмный фон страниц
  bool _counted = false;

  final _scroll = ScrollController();
  final _pager = PageController();
  double _pageExtent = 600; // высота одной страницы в режиме ленты

  /// Сколько глав в тайтле. null, если пока неизвестно.
  int? get _total {
    final total = ref.read(unitsTotalProvider(widget.item));
    return total > 0 ? total : null;
  }

  /// Сколько страниц в главе. Страницы рисуются кодом (сканов в приложении
  /// нет), поэтому число страниц для каждой главы своё, но постоянное.
  int get _pages => 14 + ((widget.item.id + _chapter) * 7) % 12;

  @override
  void initState() {
    super.initState();
    _chapter = widget.chapter;
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_horizontal || !_scroll.hasClients) return;
    final page = (_scroll.offset / _pageExtent).round().clamp(0, _pages - 1);
    _setPage(page);
  }

  void _setPage(int page) {
    if (page == _page) return;
    setState(() => _page = page);
    if (page >= _pages - 1) _countChapter();
  }

  /// Глава засчитана, когда дочитали до последней страницы.
  void _countChapter() {
    if (_counted) return;
    _counted = true;
    // Откладываем: нельзя менять состояние посреди пересчёта экрана
    Future.microtask(() {
      if (!mounted) return;
      final current = ref.read(libraryProvider)[widget.item.id]?.progress ?? 0;
      final notifier = ref.read(libraryProvider.notifier);
      if (ref.read(libraryProvider)[widget.item.id] == null) {
        notifier.setStatus(widget.item, LibraryStatus.inProgress);
      }
      if (_chapter > current) notifier.setProgress(widget.item, _chapter);
    });
  }

  void _goToChapter(int chapter) {
    if (chapter < 1 || (_total != null && chapter > _total!)) return;
    setState(() {
      _chapter = chapter;
      _page = 0;
      _counted = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (_pager.hasClients) _pager.jumpToPage(0);
  }

  void _jumpToPage(int page) {
    if (_horizontal) {
      if (_pager.hasClients) _pager.jumpToPage(page);
    } else if (_scroll.hasClients) {
      _scroll.jumpTo(page * _pageExtent);
    }
    _setPage(page);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    ref.watch(unitsTotalProvider(widget.item)); // число глав может подгрузиться
    final unit = ref.watch(unitProvider((item: widget.item, number: _chapter)));
    final isLast = _total != null && _chapter >= _total!;

    return Scaffold(
      backgroundColor: _dark
          ? const Color(0xFF16161C)
          : const Color(0xFFE9E5D8),
      body: Stack(
        children: [
          // Сами страницы: тап по ним прячет и показывает панели
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _barsVisible = !_barsVisible),
            child: _horizontal ? _buildPager() : _buildScroll(),
          ),
          // Верхняя панель
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _barsVisible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 200),
              child: _TopBar(
                title: widget.item.title,
                subtitle: [
                  if (unit?.volume != null) 'Том ${unit!.volume}',
                  'Глава $_chapter',
                  if (unit?.title != null) unit!.title!,
                ].join(' · '),
                onBack: () => Navigator.of(context).pop(),
                onChapters: _showChapters,
                onSettings: _showSettings,
              ),
            ),
          ),
          // Нижняя панель: номер страницы и перемотка
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _barsVisible ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black,
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  MediaQuery.paddingOf(context).bottom + 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${_page + 1} / $_pages',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Expanded(
                      child: Slider(
                        value: _page.toDouble(),
                        min: 0,
                        max: (_pages - 1).toDouble(),
                        divisions: _pages - 1,
                        onChanged: (v) => _jumpToPage(v.round()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Карточка в конце главы
          if (_page >= _pages - 1)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 70,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isLast
                            ? 'Это последняя глава'
                            : 'Глава $_chapter прочитана',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!isLast)
                      FilledButton(
                        onPressed: () => _goToChapter(_chapter + 1),
                        child: const Text('Дальше'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScroll() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Страница чуть выше, чем шире, как настоящий лист манги
        _pageExtent = constraints.maxWidth / 0.68;
        return ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 56,
            bottom: 56,
          ),
          itemExtent: _pageExtent,
          itemCount: _pages,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: MangaPage(seed: _chapter * 1000 + i, dark: _dark),
          ),
        );
      },
    );
  }

  Widget _buildPager() {
    return PageView.builder(
      controller: _pager,
      itemCount: _pages,
      onPageChanged: _setPage,
      itemBuilder: (context, i) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + 56,
          bottom: 56,
        ),
        child: MangaPage(seed: _chapter * 1000 + i, dark: _dark),
      ),
    );
  }

  void _showChapters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ChaptersSheet(
        item: widget.item,
        current: _chapter,
        onSelect: (number) {
          Navigator.of(sheetContext).pop();
          _goToChapter(number);
        },
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Настройки чтения',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Режим'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.swap_vert_rounded),
                            label: Text('Лента'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.swap_horiz_rounded),
                            label: Text('Страницы'),
                          ),
                        ],
                        selected: {_horizontal},
                        onSelectionChanged: (v) {
                          setSheetState(() {});
                          setState(() {
                            _horizontal = v.first;
                            _page = 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Фон'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Бумага'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Ночь'),
                          ),
                        ],
                        selected: {_dark},
                        onSelectionChanged: (v) {
                          setSheetState(() {});
                          setState(() => _dark = v.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onChapters,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onChapters;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.paddingOf(context).top + 4,
        4,
        8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onChapters,
            color: Colors.white,
            icon: const Icon(Icons.format_list_bulleted_rounded),
          ),
          IconButton(
            onPressed: onSettings,
            color: Colors.white,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}

/// Список глав: по томам, если Kitsu знает тома, иначе общим списком.
class _ChaptersSheet extends ConsumerWidget {
  const _ChaptersSheet({
    required this.item,
    required this.current,
    required this.onSelect,
  });

  final MediaItem item;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = math.max(ref.watch(unitsTotalProvider(item)), current);
    final chapters = ref.watch(mangaChaptersProvider(item)).value;
    final volumes = chapters == null
        ? const <int, List<MediaUnit>>{}
        : groupByVolume(chapters);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Главы',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: volumes.isEmpty
                ? ListView.builder(
                    itemCount: total,
                    itemBuilder: (context, i) => Consumer(
                      builder: (context, ref, _) => _ChapterTile(
                        number: i + 1,
                        unit: ref.watch(
                          unitProvider((item: item, number: i + 1)),
                        ),
                        selected: i + 1 == current,
                        onTap: () => onSelect(i + 1),
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (final entry in volumes.entries)
                        ExpansionTile(
                          initiallyExpanded: entry.value.any(
                            (c) => c.number == current,
                          ),
                          shape: const Border(),
                          collapsedShape: const Border(),
                          title: Text(
                            'Том ${entry.key}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          children: [
                            for (final chapter in entry.value)
                              _ChapterTile(
                                number: chapter.number,
                                unit: chapter,
                                selected: chapter.number == current,
                                onTap: () => onSelect(chapter.number),
                              ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.number,
    required this.unit,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final MediaUnit? unit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = unit?.title;
    return ListTile(
      title: Text(title ?? 'Глава $number'),
      subtitle: title == null ? null : Text('Глава $number'),
      selected: selected,
      trailing: selected
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
