import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/store_catalog.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/profile/favorites_page.dart';
import 'package:nexora/presentation/pages/profile/profile_editor_page.dart';
import 'package:nexora/presentation/pages/profile/profile_sections_pages.dart';
import 'package:nexora/presentation/pages/profile/showcase_blocks.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_layout_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/reviews_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/profile_widgets.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const double _bannerHeight = 190;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);
    final layout = ref.watch(profileLayoutProvider);
    final library = ref.watch(libraryProvider);
    final favorites = ref.watch(favoritesProvider);
    final reviews = ref.watch(reviewsProvider);
    final top = MediaQuery.paddingOf(context).top;

    final entries = library.values.toList();
    final animeCount =
        entries.where((e) => e.item.type == MediaType.anime).length;
    final mangaCount = entries.length - animeCount;
    final myReviews = [
      for (final list in reviews.values)
        for (final r in list)
          if (r.mine) r,
    ].length;

    // Что смотрит прямо сейчас: самая свежая запись аниме со статусом «Смотрю»
    final watching = entries
        .where((e) =>
    e.status == LibraryStatus.inProgress &&
        e.item.type == MediaType.anime)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final presence = watching.isEmpty
        ? 'В сети'
        : 'В сети · смотрит ${watching.first.item.title}';

    final realName = layout.showRealName ? layout.realName.trim() : '';
    final location = layout.showLocation ? layout.location.trim() : '';
    final status = layout.showStatus ? layout.status.trim() : '';

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Баннер, аватар и имя
          SizedBox(
            height: _bannerHeight + top + 64,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _bannerHeight + top,
                  child: BannerArt(
                    bannerId: profile.bannerId,
                    imagePath: profile.bannerPath,
                    adjust: profile.bannerAdjust,
                  ),
                ),
                Positioned(
                  top: top + 8,
                  right: 12,
                  child: _BannerButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Редактировать',
                    onTap: () => _push(context, const ProfileEditorPage()),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: ProfileAvatar(
                    text: profile.avatarText,
                    frameId: profile.frameId,
                    imagePath: profile.avatarPath,
                    adjust: profile.avatarAdjust,
                    level: profile.level,
                    size: 112,
                  ),
                ),
                Positioned(
                  left: 144,
                  right: 16,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (layout.showPresence) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 9,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                presence,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 15,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              storeItemById(profile.badgeId).title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Настоящее имя, город, статус, о себе
          if (realName.isNotEmpty || location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (realName.isNotEmpty)
                    _InfoChip(icon: Icons.badge_outlined, text: realName),
                  if (location.isNotEmpty)
                    _InfoChip(icon: Icons.place_outlined, text: location),
                ],
              ),
            ),
          if (status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                '«$status»',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          if (profile.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                profile.bio,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ),

          // Кнопки
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _push(context, const ProfileEditorPage()),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    label: const Text('Редактировать профиль'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SquareButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(
                      text:
                      '${profile.name} в Nexora · уровень ${profile.level}',
                    ));
                    if (context.mounted) {
                      showInfo(context, 'Ссылка на профиль скопирована');
                    }
                  },
                ),
              ],
            ),
          ),

          // Уровень
          if (layout.showLevel)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Уровень ${profile.level}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatNumber(profile.xpInLevel)} / ${formatNumber(kXpPerLevel)} XP',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ThinProgressBar(
                    value: profile.xpInLevel / kXpPerLevel,
                    color: scheme.primary,
                    trackColor: scheme.surfaceContainerHighest,
                    height: 8,
                  ),
                ],
              ),
            ),

          // Разделы профиля (как «Игры, Друзья, Отзывы» в Steam)
          if (layout.showSections)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Material(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _SectionRow(
                      icon: Icons.movie_outlined,
                      title: 'Аниме',
                      count: animeCount,
                      onTap: () => _push(
                        context,
                        const ProfileTitlesPage(type: MediaType.anime),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SectionRow(
                      icon: Icons.menu_book_outlined,
                      title: 'Манга',
                      count: mangaCount,
                      onTap: () => _push(
                        context,
                        const ProfileTitlesPage(type: MediaType.manga),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SectionRow(
                      icon: Icons.favorite_border_rounded,
                      title: 'Избранное',
                      count: favorites.length,
                      onTap: () => _push(context, const FavoritesPage()),
                    ),
                    const Divider(height: 1, indent: 56),
                    _SectionRow(
                      icon: Icons.bookmarks_outlined,
                      title: 'Списки',
                      count: entries.length,
                      onTap: () {
                        // Закрываем профиль и открываем вкладку «Библиотека»
                        Navigator.of(context).popUntil((r) => r.isFirst);
                        ref.read(shellTabProvider.notifier).setTab(2);
                      },
                    ),
                    const Divider(height: 1, indent: 56),
                    _SectionRow(
                      icon: Icons.rate_review_outlined,
                      title: 'Отзывы',
                      count: myReviews,
                      onTap: () => _push(context, const MyReviewsPage()),
                    ),
                  ],
                ),
              ),
            ),

          // Витрины в выбранном порядке
          for (final type in layout.shown) ShowcaseBlock(type: type),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(width: 50, height: 50, child: Icon(icon)),
      ),
    );
  }
}