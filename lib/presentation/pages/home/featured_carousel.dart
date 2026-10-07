import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/home_feed.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/detail/detail_sheets.dart';
import 'package:nexora/presentation/pages/player/watch_page.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/widgets/hero_size.dart';
import 'package:nexora/presentation/widgets/media_cover.dart';

/// Большая карточка сверху (как на Кинопоиске): листается раз в 5 секунд,
/// точки под ней кликабельны.
class FeaturedCarousel extends StatefulWidget {
  const FeaturedCarousel({super.key, required this.banners});

  final List<FeaturedBanner> banners;

  @override
  State<FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<FeaturedCarousel> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.banners.isEmpty || !_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % widget.banners.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: heroHeight(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.banners.length,
                onPageChanged: (i) {
                  setState(() => _page = i);
                  _startTimer();
                },
                itemBuilder: (_, i) => _Slide(banner: widget.banners[i]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.banners.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i == _page ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _page
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Slide extends ConsumerWidget {
  const _Slide({required this.banner});

  final FeaturedBanner banner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final item = banner.item;
    final entry = ref.watch(libraryProvider.select((m) => m[item.id]));
    final inLibrary = entry != null;
    final hasProgress = entry != null && entry.progress > 0;

    return GestureDetector(
      onTap: () => openDetail(context, item),
      child: MediaCover(
        item: item,
        hd: true, // большая карточка: постер в высоком качестве
        // Тёмный градиент снизу, чтобы белый текст читался на любой обложке
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.45, 1.0],
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.82),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Pill(text: banner.badge),
                    const Spacer(),
                    if (item.rating > 0)
                      _Pill(text: '★ ${item.rating.toStringAsFixed(1)}'),
                  ],
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                // «2005 · Comedy · Sci-Fi»
                Text(
                  banner.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: FilledButton.icon(
                        onPressed: () => openWatch(
                          context,
                          item,
                          episode: entry?.next ?? 1,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          hasProgress ? 'Продолжить' : 'Смотреть',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6,
                      child: FilledButton(
                        onPressed: () => showStatusSheet(context, item),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          inLibrary ? 'В списке ✓' : 'Буду смотреть',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Тёмная пилюля на обложке («Сейчас в эфире», «★ 7.7»).
class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}