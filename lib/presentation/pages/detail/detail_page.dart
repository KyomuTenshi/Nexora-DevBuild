import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/catalog/catalog_grid.dart';
import 'package:nexora/presentation/pages/player/watch_page.dart';
import 'package:nexora/presentation/pages/reader/reader_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/ratings_provider.dart';
import 'package:nexora/presentation/providers/reviews_provider.dart';
import 'package:nexora/presentation/providers/similar_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';
import 'package:nexora/presentation/widgets/error_view.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'detail_header.dart';

/// Открывает страницу тайтла. На неделе 7 заменим на GoRouter.
void openDetail(BuildContext context, MediaItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => DetailPage(item: item)),
  );
}

enum _DetailTab { description, episodes, reviews, similar }

class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key, required this.item});

  final MediaItem item;

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  _DetailTab _tab = _DetailTab.description;

  String _tabLabel(_DetailTab tab) => switch (tab) {
        _DetailTab.description => 'Описание',
        _DetailTab.episodes =>
          widget.item.type == MediaType.anime ? 'Серии' : 'Главы',
        _DetailTab.reviews => 'Отзывы',
        _DetailTab.similar => 'Похожее',
      };

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final entry = ref.watch(libraryProvider.select((m) => m[item.id]));

    return Scaffold(
      // CustomScrollView + slivers: общий скролл, а длинный список серий
      // строится лениво (только видимые строки).
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: DetailHero(item: item)),
          SliverToBoxAdapter(child: DetailInfo(item: item, entry: entry)),
          SliverToBoxAdapter(child: _buildTabBar(context)),
          ..._buildTabContent(context, item, entry),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      // Если вкладки не помещаются в ширину, их можно листать вбок
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            for (final tab in _DetailTab.values)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _tab = tab),
                child: Padding(
                  padding: const EdgeInsets.only(right: 22),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            _tabLabel(tab),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: tab == _tab
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          height: 2,
                          color:
                              tab == _tab ? scheme.primary : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabContent(
    BuildContext context,
    MediaItem item,
    LibraryEntry? entry,
  ) {
    final scheme = Theme.of(context).colorScheme;

    switch (_tab) {
      case _DetailTab.description:
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                item.synopsis.isEmpty
                    ? 'Описание пока недоступно.'
                    : item.synopsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ];

      case _DetailTab.episodes:
        if (item.totalUnits == 0) {
          return const [
            SliverToBoxAdapter(
              child: EmptyView(
                icon: Icons.movie_outlined,
                title: 'Список пока пуст',
                message: 'Информация об эпизодах появится позже.',
              ),
            ),
          ];
        }
        final progress = entry?.progress ?? 0;
        final isAnime = item.type == MediaType.anime;
        final word = isAnime ? 'Серия' : 'Глава';
        return [
          SliverList.builder(
            itemCount: item.totalUnits,
            itemBuilder: (context, index) {
              final number = index + 1;
              final done = number <= progress;
              return ListTile(
                contentPadding: const EdgeInsets.only(left: 16, right: 4),
                leading: Icon(
                  isAnime ? Icons.play_circle_outline_rounded : Icons.article_outlined,
                  color: scheme.onSurfaceVariant,
                ),
                title: Text('$word $number'),
                // Тап по строке запускает серию (читалку), галочка отмечает вручную
                onTap: () => isAnime
                    ? openWatch(context, item, episode: number)
                    : openReader(context, item, chapter: number),
                trailing: IconButton(
                  tooltip: done ? 'Снять отметку' : 'Отметить пройденной',
                  icon: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: done ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    final target = done ? number - 1 : number;
                    ref.read(libraryProvider.notifier).setProgress(item, target);
                    showInfo(
                      context,
                      done ? 'Отметка снята' : 'Отмечена: $word $number',
                    );
                  },
                ),
              );
            },
          ),
        ];

      case _DetailTab.reviews:
        final reviews = ref.watch(
          reviewsProvider.select((m) => m[item.id]),
        );
        final list = reviews ?? ref.read(reviewsProvider.notifier).of(item.id);
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${list.length} ${pluralReviews(list.length)}',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showReviewSheet(context, item),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Написать отзыв'),
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: list.length,
            itemBuilder: (context, i) => _ReviewTile(review: list[i]),
          ),
        ];

      case _DetailTab.similar:
        final similar = ref.watch(similarProvider(item));
        return [
          similar.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorView(
                onRetry: () => ref.invalidate(similarProvider(item)),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'Похожих тайтлов нет',
                    message: 'Попробуйте заглянуть в каталог.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => CatalogCard(item: items[i]),
                ),
              );
            },
          ),
        ];
    }
  }

  void _showReviewSheet(BuildContext context, MediaItem item) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          // Поднимаем шторку над клавиатурой
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ваш отзыв',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      hintText: 'Что вам понравилось или не понравилось?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;
                        final profile = ref.read(profileProvider);
                        final rating = ref.read(ratingsProvider)[item.id] ?? 0;
                        ref.read(reviewsProvider.notifier).add(
                              item.id,
                              Review(
                                author: profile.name,
                                rating: rating,
                                text: text,
                                ago: 'только что',
                                mine: true,
                              ),
                            );
                        Navigator.of(sheetContext).pop();
                        showInfo(context, 'Отзыв опубликован · +50 очков');
                      },
                      child: const Text('Опубликовать'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String pluralReviews(int n) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return 'отзывов';
  if (mod10 == 1) return 'отзыв';
  if (mod10 >= 2 && mod10 <= 4) return 'отзыва';
  return 'отзывов';
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: review.mine ? Border.all(color: scheme.primary) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary.withValues(alpha: 0.2),
                child: Text(
                  review.author.isEmpty
                      ? '?'
                      : review.author[0].toUpperCase(),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.mine ? '${review.author} (вы)' : review.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (review.rating > 0) ...[
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC53D)),
                const SizedBox(width: 2),
                Text(
                  '${review.rating}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(review.text, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 6),
          Text(
            review.ago,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
