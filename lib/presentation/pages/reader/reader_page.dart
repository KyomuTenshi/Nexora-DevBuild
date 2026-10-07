import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/reader/manga_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';

/// Открывает читалку на нужной главе.
void openReader(BuildContext context, MediaItem item, {required int chapter}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReaderPage(item: item, chapter: chapter),
    ),
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
  /// Сколько страниц в главе (демо-значение).
  static const int _pages = 18;

  late int _chapter;
  int _page = 0;
  bool _barsVisible = true;
  bool _horizontal = false; // false: лента вниз, true: листаем страницы
  bool _dark = false; // тёмный фон страниц
  bool _counted = false;

  final _scroll = ScrollController();
  final _pager = PageController();
  double _pageExtent = 600; // высота одной страницы в режиме ленты

  int? get _total =>
      widget.item.totalUnits > 0 ? widget.item.totalUnits : null;

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

  int get _volume => math.max(1, _chapter ~/ 9);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _total != null && _chapter >= _total!;

    return Scaffold(
      backgroundColor: _dark ? const Color(0xFF16161C) : const Color(0xFFE9E5D8),
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
                subtitle: 'Том $_volume · Глава $_chapter',
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
                        isLast ? 'Это последняя глава' : 'Глава $_chapter прочитана',
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
    final total = _total ?? (_chapter + 5);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Главы',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: total,
                  itemBuilder: (context, i) {
                    final number = i + 1;
                    final current = number == _chapter;
                    return ListTile(
                      title: Text('Глава $number'),
                      trailing: current
                          ? Icon(Icons.check_rounded, color: scheme.primary)
                          : null,
                      selected: current,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _goToChapter(number);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
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
