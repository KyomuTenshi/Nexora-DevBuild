import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/providers/home_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:nexora/presentation/widgets/media_cover.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/skeleton.dart';

/// Запросы для блока «Часто ищут». Kitsu ищет по английским названиям.
const _kPopularTerms = [
  'One Piece',
  'Naruto',
  'Attack on Titan',
  'Death Note',
  'Berserk',
  'Jujutsu Kaisen',
  'Chainsaw Man',
  'Fullmetal Alchemist',
  'Bleach',
  'Spy x Family',
];

/// Поле поиска с выпадающей панелью, как в Steam. Стоит на Главной и в Каталоге.
/// Текст хранится в catalogQueryProvider, поэтому оба поля показывают один запрос.
/// Запрос уходит после паузы в 350 мс (debounce).
class SearchBox extends ConsumerStatefulWidget {
  const SearchBox({
    super.key,
    this.height = 46,
    this.radius = 14,
    this.trailing,
  });

  final double height;
  final double radius;

  /// Кнопка справа внутри поля (например, фильтры в Каталоге).
  final Widget? trailing;

  @override
  ConsumerState<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends ConsumerState<SearchBox> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  final _focus = FocusNode();
  late final TextEditingController _controller;
  Timer? _debounce;

  /// Меняется при каждом открытии панели: от него зависит «как повезёт».
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(catalogQueryProvider).text,
    );
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      _seed = DateTime.now().millisecondsSinceEpoch;
      if (!_portal.isShowing) _portal.show();
    } else if (_portal.isShowing) {
      _portal.hide();
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) ref.read(catalogQueryProvider.notifier).setText(value);
    });
  }

  /// Записать текст сразу, без паузы (подсказка, кнопка очистки).
  void _setNow(String value) {
    _debounce?.cancel();
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    ref.read(catalogQueryProvider.notifier).setText(value);
  }

  void _close() => _focus.unfocus();

  void _openCatalog() {
    _debounce?.cancel();
    ref.read(catalogQueryProvider.notifier).setText(_controller.text);
    ref.read(shellTabProvider.notifier).setTab(1);
    _close();
  }

  void _openTitle(MediaItem item) {
    _close();
    openDetail(context, item);
  }

  Widget _buildOverlay(BuildContext context) {
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size ?? Size.zero;
    final fieldBottom =
    box == null ? 0.0 : box.localToGlobal(Offset(0, box.size.height)).dy;
    final media = MediaQuery.of(context);

    // Панель не должна уходить под клавиатуру
    final maxHeight =
    (media.size.height - media.viewInsets.bottom - fieldBottom - 16)
        .clamp(160.0, 520.0);

    return Stack(
      children: [
        // Тёмная подложка: нажатие закрывает панель
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: const ColoredBox(color: Colors.black38),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: SizedBox(
            width: size.width,
            child: _SearchPanel(
              controller: _controller,
              seed: _seed,
              maxHeight: maxHeight,
              onTerm: _setNow,
              onItem: _openTitle,
              onAll: _openCatalog,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Текст изменили снаружи (например, «Сбросить»): обновляем поле
    ref.listen<String>(catalogQueryProvider.select((q) => q.text),
            (previous, next) {
          if (_controller.text != next) {
            _controller.text = next;
            _controller.selection = TextSelection.collapsed(offset: next.length);
          }
        });

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlay,
      child: CompositedTransformTarget(
        link: _link,
        child: Container(
          key: _fieldKey,
          height: widget.height,
          padding: const EdgeInsets.only(left: 14, right: 8),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  onSubmitted: (_) => _openCatalog(),
                  // Закрывает только подложка панели, а не любой тап рядом
                  onTapOutside: (_) {},
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Найти аниме или мангу',
                    hintStyle: TextStyle(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    onPressed: () => _setNow(''),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close_rounded, size: 20),
                  );
                },
              ),
              ?widget.trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Выпадающая панель: подсказки или результаты поиска.
class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.seed,
    required this.maxHeight,
    required this.onTerm,
    required this.onItem,
    required this.onAll,
  });

  final TextEditingController controller;
  final int seed;
  final double maxHeight;
  final ValueChanged<String> onTerm;
  final ValueChanged<MediaItem> onItem;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 12,
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final text = value.text.trim();
              return text.isEmpty
                  ? _Suggestions(seed: seed, onTerm: onTerm, onItem: onItem)
                  : _Results(text: text, onItem: onItem, onAll: onAll);
            },
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// «Часто ищут» и 4 случайных тайтла.
class _Suggestions extends ConsumerWidget {
  const _Suggestions({
    required this.seed,
    required this.onTerm,
    required this.onItem,
  });

  final int seed;
  final ValueChanged<String> onTerm;
  final ValueChanged<MediaItem> onItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terms = [..._kPopularTerms]..shuffle(Random(seed));

    final feed = ref.watch(homeFeedProvider).value;
    final pool = feed == null
        ? <MediaItem>[]
        : <MediaItem>{
      for (final b in feed.featured) b.item,
      ...feed.popular,
    }.toList();
    pool.shuffle(Random(seed + 1));
    final picks = pool.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('Часто ищут'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in terms.take(6))
                ActionChip(label: Text(t), onPressed: () => onTerm(t)),
            ],
          ),
        ),
        if (picks.isNotEmpty) ...[
          const _Label('Попробуйте'),
          for (final item in picks)
            _TitleRow(item: item, onTap: () => onItem(item)),
        ],
      ],
    );
  }
}

/// Результаты поиска: до 5 строк и переход в Каталог.
class _Results extends ConsumerWidget {
  const _Results({
    required this.text,
    required this.onItem,
    required this.onAll,
  });

  final String text;
  final ValueChanged<MediaItem> onItem;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final queryText = ref.watch(catalogQueryProvider.select((q) => q.text));
    final results = ref.watch(catalogResultsProvider);

    // Пока запрос не ушёл (пауза 350 мс), старые результаты не показываем
    if (queryText.trim() != text) return const _LoadingRows();

    return results.when(
      skipLoadingOnReload: true,
      loading: () => const _LoadingRows(),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(child: Text('Не удалось выполнить поиск')),
            TextButton(
              onPressed: () => ref.invalidate(catalogResultsProvider),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ничего не найдено по запросу «$text»',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return Column(
          children: [
            for (final item in items.take(5))
              _TitleRow(item: item, onTap: () => onItem(item)),
            InkWell(
              onTap: onAll,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: scheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Все результаты в каталоге',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.item, required this.onTap});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 62,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MediaCover(item: item),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.type.label} · ${item.year ?? '—'}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
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

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    // Без const у Column и SkeletonShimmer: в const-выражении нельзя писать for
    return SkeletonShimmer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  SkeletonBox(width: 44, height: 62, radius: 8),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 14, radius: 6),
                        SizedBox(height: 8),
                        SkeletonBox(width: 90, height: 11, radius: 5),
                      ],
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