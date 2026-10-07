import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/presentation/providers/home_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:nexora/presentation/providers/similar_provider.dart';
import 'package:nexora/presentation/widgets/cached_data_banner.dart';
import 'package:nexora/presentation/widgets/error_view.dart';
import 'package:nexora/presentation/widgets/section_header.dart';
import 'package:nexora/presentation/widgets/skeleton.dart';
import 'continue_reading_section.dart';
import 'continue_watching_section.dart';
import 'featured_carousel.dart';
import 'home_top_bar.dart';
import 'popular_section.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider);
    final hasActive = ref.watch(libraryProvider.select(
          (m) => m.values.any((e) => e.status == LibraryStatus.inProgress),
    ));

    return Scaffold(
      body: SafeArea(
        bottom: false, // список заезжает под размытую панель
        child: feed.when(
          // Вместо крутилки: поиск остаётся доступным, ниже серые заготовки
          loading: () => ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: const [HomeTopBar(), HomeSkeleton()],
          ),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(homeFeedProvider),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              // Сбрасываем кэш, иначе получим те же сохранённые данные
              ref.read(mediaRepositoryProvider).clearCache();
              ref.invalidate(recommendedProvider);
              ref.invalidate(homeFeedProvider);
              try {
                await ref.read(homeFeedProvider.future);
              } catch (_) {
                // Ошибку покажет сам экран (ErrorView с кнопкой «Повторить»)
              }
            },
            child: ListView(
              children: [
                const HomeTopBar(),
                const CachedDataBanner(),
                FeaturedCarousel(banners: data.featured),
                if (hasActive) ...[
                  const ContinueWatchingSection(),
                  const ContinueReadingSection(),
                ] else
                  const _StartCard(),
                const RecommendedSection(),
                SectionHeader(
                  title: 'Сейчас популярно',
                  onSeeAll: () => ref.read(shellTabProvider.notifier).setTab(1),
                ),
                PopularSection(items: data.popular),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Подсказка для пользователя с пустой библиотекой.
class _StartCard extends ConsumerWidget {
  const _StartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.explore_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Начните с каталога',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text('Добавьте тайтл в список, и он появится здесь.'),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => ref.read(shellTabProvider.notifier).setTab(1),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
  }
}