import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_summary.dart';
import 'package:nexora/presentation/pages/library/library_labels.dart';
import 'package:nexora/presentation/pages/player/watch_page.dart';
import 'package:nexora/presentation/pages/reader/reader_page.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/ratings_provider.dart';
import 'package:nexora/presentation/widgets/media_cover.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/star_rating.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';
import 'detail_sheets.dart';

/// «Поделиться»: пока копируем текст со ссылкой в буфер обмена.
Future<void> shareItem(BuildContext context, MediaItem item) async {
  await Clipboard.setData(
    ClipboardData(text: '«${item.title}» в Nexora · nexora://title/${item.id}'),
  );
  if (context.mounted) showInfo(context, 'Ссылка скопирована');
}

/// Верхняя часть страницы: постер, кнопки, название.
class DetailHero extends ConsumerWidget {
  const DetailHero({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final isFavorite =
    ref.watch(favoritesProvider.select((s) => s.containsKey(item.id)));

    final subtitle = [
      if (item.year != null) '${item.year}',
      item.type == MediaType.anime ? 'TV' : 'Манга',
      unitsLabel(item),
    ].join(' · ');

    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Постер в высоком качестве: он занимает почти весь экран
          MediaCover(item: item, hd: true),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, background],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  children: [
                    _RoundButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    _RoundButton(
                      icon: Icons.ios_share_rounded,
                      onTap: () => shareItem(context, item),
                    ),
                    const SizedBox(width: 8),
                    _RoundButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? AppColors.pink : Colors.white,
                      onTap: () {
                        ref.read(favoritesProvider.notifier).toggle(item);
                        showInfo(
                          context,
                          isFavorite
                              ? 'Убрано из избранного'
                              : 'Добавлено в избранное',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

/// Рейтинг, жанры, главная кнопка, прогресс, быстрые действия и выжимка.
class DetailInfo extends ConsumerWidget {
  const DetailInfo({super.key, required this.item, required this.entry});

  final MediaItem item;
  final LibraryEntry? entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final myRating = ref.watch(ratingsProvider.select((m) => m[item.id] ?? 0));
    final isAnime = item.type == MediaType.anime;

    final done = entry != null &&
        item.totalUnits > 0 &&
        entry!.progress >= item.totalUnits;
    final unit = done ? 1 : (entry?.next ?? 1);
    final mainLabel = isAnime
        ? '${done ? 'Пересмотреть' : 'Смотреть'} · серия $unit'
        : '${done ? 'Перечитать' : 'Читать'} · глава $unit';

    final tags = [...item.genres, ?item.studio];
    final summary = shortSummary(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: item.rating >= 8.5
                        ? AppColors.success
                        : AppColors.star,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Рейтинг Nexora',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      votesLabel(item.votes),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Моя оценка',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  StarRating(
                    value: myRating,
                    size: 20,
                    onChanged: (v) =>
                        ref.read(ratingsProvider.notifier).set(item.id, v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: () => isAnime
                  ? openWatch(context, item, episode: unit)
                  : openReader(context, item, chapter: unit),
              icon: Icon(
                isAnime ? Icons.play_arrow_rounded : Icons.menu_book_rounded,
              ),
              label: Text(
                mainLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Прогресс просмотра или чтения (если тайтл в списках)
          if (entry != null && item.totalUnits > 0) ...[
            const SizedBox(height: 12),
            _ProgressStrip(item: item, entry: entry!),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: entry == null
                      ? Icons.bookmark_border_rounded
                      : Icons.bookmark_rounded,
                  label: entry?.status.labelFor(item.type) ?? 'В список',
                  highlighted: entry != null,
                  onTap: () => showStatusSheet(context, item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: myRating > 0
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  label: myRating > 0 ? 'Оценка $myRating' : 'Оценить',
                  highlighted: myRating > 0,
                  onTap: () => showRateSheet(context, item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Поделиться',
                  onTap: () => shareItem(context, item),
                ),
              ),
            ],
          ),

          // Выжимка: о чём и чем удивит (1–2 предложения)
          if (summary != null) ...[
            const SizedBox(height: 18),
            _SummaryCard(text: summary),
          ],
        ],
      ),
    );
  }
}

/// «Просмотрено 5 из 12 серий» и полоса прогресса.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.item, required this.entry});

  final MediaItem item;
  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final verb = item.type == MediaType.anime ? 'Просмотрено' : 'Прочитано';
    final percent = (entry.fraction * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$verb ${entry.progress} из ${item.totalUnits} '
                    '${unitWord(item.type, item.totalUnits)}',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ThinProgressBar(
          value: entry.fraction,
          color: scheme.primary,
          trackColor: scheme.surfaceContainerHighest,
          height: 6,
        ),
      ],
    );
  }
}

/// Короткая выжимка с акцентной полосой слева.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: scheme.primary),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = highlighted ? scheme.primary : scheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}