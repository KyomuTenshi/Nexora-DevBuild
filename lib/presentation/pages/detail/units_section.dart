import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_unit.dart';
import 'package:nexora/presentation/pages/player/watch_page.dart';
import 'package:nexora/presentation/pages/reader/reader_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/units_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';
import 'package:nexora/presentation/widgets/error_view.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

/// Вкладка «Серии» (у манги «Главы»): названия и превью серий из Kitsu,
/// у манги ещё разбивка по томам. Список строится лениво, а данные
/// подгружаются страницами по мере прокрутки.
class UnitsSection extends ConsumerStatefulWidget {
  const UnitsSection({super.key, required this.item});

  final MediaItem item;

  @override
  ConsumerState<UnitsSection> createState() => _UnitsSectionState();
}

class _UnitsSectionState extends ConsumerState<UnitsSection> {
  /// Порядок серий (глав). У манги по умолчанию сначала новые, как в MangaLib.
  late bool _newestFirst = widget.item.type == MediaType.manga;
  bool _byVolume = false;

  MediaItem get _item => widget.item;
  bool get _isAnime => _item.type == MediaType.anime;

  void _open(int number) => _isAnime
      ? openWatch(context, _item, episode: number)
      : openReader(context, _item, chapter: number);

  void _toggleDone(int number, bool done) {
    ref
        .read(libraryProvider.notifier)
        .setProgress(_item, done ? number - 1 : number);
    final word = _isAnime ? 'Серия' : 'Глава';
    showInfo(context, done ? 'Отметка снята' : 'Отмечена: $word $number');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = ref.watch(unitsTotalProvider(_item));
    final first = ref.watch(unitsPageProvider((item: _item, page: 0)));

    if (total == 0) {
      if (first.isLoading) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (first.hasError) {
        return SliverToBoxAdapter(
          child: ErrorView(
            error: first.error!,
            onRetry: () =>
                ref.invalidate(unitsPageProvider((item: _item, page: 0))),
          ),
        );
      }
      return const SliverToBoxAdapter(
        child: EmptyView(
          icon: Icons.movie_outlined,
          title: 'Список пока пуст',
          message: 'Информация об эпизодах появится позже.',
        ),
      );
    }

    final progress = ref.watch(
      libraryProvider.select((m) => m[_item.id]?.progress ?? 0),
    );
    final hasEntry = ref.watch(
      libraryProvider.select((m) => m.containsKey(_item.id)),
    );
    final nextNumber = hasEntry && progress < total ? progress + 1 : null;

    // Тома есть только у манги и только если Kitsu знает номер тома
    final chapters = _isAnime
        ? null
        : ref.watch(mangaChaptersProvider(_item)).value;
    final volumes = chapters == null
        ? const <int, List<MediaUnit>>{}
        : groupByVolume(chapters);
    final showVolumes = _byVolume && volumes.isNotEmpty;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        volumes.isEmpty
                            ? '$total ${unitWord(_item.type, total)}'
                            : '$total ${unitWord(_item.type, total)} · '
                                  '${volumes.length} т.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _newestFirst = !_newestFirst),
                      icon: Icon(
                        _newestFirst
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _newestFirst ? 'Сначала новые' : 'Сначала старые',
                      ),
                    ),
                  ],
                ),
                if (volumes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 8),
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('Главы')),
                        ButtonSegment(value: true, label: Text('Тома')),
                      ],
                      selected: {_byVolume},
                      onSelectionChanged: (s) =>
                          setState(() => _byVolume = s.first),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showVolumes)
          _buildVolumes(volumes, progress, nextNumber)
        else
          SliverList.builder(
            itemCount: total,
            itemBuilder: (context, index) {
              final number = _newestFirst ? total - index : index + 1;
              return Consumer(
                builder: (context, ref, _) => _UnitTile(
                  item: _item,
                  number: number,
                  unit: ref.watch(unitProvider((item: _item, number: number))),
                  done: number <= progress,
                  isNext: number == nextNumber,
                  onOpen: () => _open(number),
                  onToggle: () => _toggleDone(number, number <= progress),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVolumes(
    Map<int, List<MediaUnit>> volumes,
    int progress,
    int? nextNumber,
  ) {
    final numbers = volumes.keys.toList();
    if (_newestFirst) numbers.sort((a, b) => b.compareTo(a));

    return SliverList.builder(
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final volume = numbers[index];
        final list = [...volumes[volume]!]
          ..sort(
            (a, b) => _newestFirst
                ? b.number.compareTo(a.number)
                : a.number.compareTo(b.number),
          );
        final doneCount = list.where((c) => c.number <= progress).length;

        return ExpansionTile(
          key: PageStorageKey('volume-$volume'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            'Том $volume',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('Прочитано $doneCount из ${list.length}'),
          children: [
            for (final chapter in list)
              _UnitTile(
                item: _item,
                number: chapter.number,
                unit: chapter,
                showVolume: false,
                done: chapter.number <= progress,
                isNext: chapter.number == nextNumber,
                onOpen: () => _open(chapter.number),
                onToggle: () =>
                    _toggleDone(chapter.number, chapter.number <= progress),
              ),
          ],
        );
      },
    );
  }
}

/// Одна строка списка: серия или глава.
class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.item,
    required this.number,
    required this.unit,
    required this.done,
    required this.isNext,
    required this.onOpen,
    required this.onToggle,
    this.showVolume = true,
  });

  final MediaItem item;
  final int number;

  /// Данные из Kitsu. null, пока они не загрузились или их нет.
  final MediaUnit? unit;
  final bool done;
  final bool isNext;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final bool showVolume;

  /// «2021-04-02» -> «02.04.2021».
  static String _date(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    final day = parts[2].split('T').first;
    return '$day.${parts[1]}.${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAnime = item.type == MediaType.anime;
    final word = isAnime ? 'Серия' : 'Глава';
    final name = unit?.title;
    final thumbnail = unit?.thumbnailUrl;

    final details = [
      if (name != null) '$word $number',
      if (isNext) isAnime ? 'Следующая серия' : 'Следующая глава',
      if (showVolume && unit?.volume != null) 'Том ${unit!.volume}',
      if (isAnime && unit?.minutes != null) '${unit!.minutes} мин',
      if (unit?.date != null) _date(unit!.date!),
    ];

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      // Следующая серия (глава) подсвечена: «продолжить отсюда»
      tileColor: isNext ? scheme.primary.withValues(alpha: 0.10) : null,
      leading: thumbnail != null && isAnime
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: thumbnail,
                width: 96,
                height: 54,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const SizedBox(width: 96, height: 54),
              ),
            )
          : Icon(
              isAnime
                  ? Icons.play_circle_outline_rounded
                  : Icons.article_outlined,
              color: isNext ? scheme.primary : scheme.onSurfaceVariant,
            ),
      title: Text(
        name ?? '$word $number',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
          color: done ? scheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      onTap: onOpen,
      trailing: IconButton(
        tooltip: done ? 'Снять отметку' : 'Отметить пройденной',
        icon: Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? scheme.primary : scheme.onSurfaceVariant,
        ),
        onPressed: onToggle,
      ),
    );
  }
}
