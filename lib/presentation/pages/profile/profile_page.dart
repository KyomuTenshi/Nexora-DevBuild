import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/store_catalog.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/profile/favorites_page.dart';
import 'package:nexora/presentation/pages/profile/profile_edit_page.dart';
import 'package:nexora/presentation/pages/profile/settings_page.dart';
import 'package:nexora/presentation/pages/profile/store_page.dart';
import 'package:nexora/presentation/providers/all_items_provider.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/ratings_provider.dart';
import 'package:nexora/presentation/widgets/cover_art.dart';
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
    final library = ref.watch(libraryProvider);
    final favorites = ref.watch(favoritesProvider);
    final ratings = ref.watch(ratingsProvider);
    final top = MediaQuery.paddingOf(context).top;

    final entries = library.values.toList();
    final completed =
        entries.where((e) => e.status == LibraryStatus.completed).length;

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

    final totalProgress = entries.fold<int>(0, (sum, e) => sum + e.progress);
    final achievements = [
      _Achievement(
        'Первый шаг',
        'Добавьте первый тайтл в библиотеку',
        Icons.emoji_events_outlined,
        AppColors.star,
        entries.isNotEmpty,
      ),
      _Achievement(
        'Марафонец',
        'Завершите хотя бы один тайтл',
        Icons.local_fire_department_outlined,
        const Color(0xFFFF8A3D),
        completed > 0,
      ),
      _Achievement(
        'Книжный червь',
        'Прочитайте главу манги',
        Icons.menu_book_outlined,
        scheme.primary,
        entries.any((e) => e.item.type == MediaType.manga && e.progress > 0),
      ),
      _Achievement(
        'Критик',
        'Поставьте оценку любому тайтлу',
        Icons.workspace_premium_outlined,
        AppColors.pink,
        ratings.isNotEmpty,
      ),
      _Achievement(
        'Зритель',
        'Посмотрите или прочитайте 100 серий и глав',
        Icons.visibility_outlined,
        const Color(0xFF3AA0F5),
        totalProgress >= 100,
      ),
      _Achievement(
        'Любимчик',
        'Добавьте 3 тайтла в избранное',
        Icons.favorite_border_rounded,
        const Color(0xFFFF5C6C),
        favorites.length >= 3,
      ),
    ];
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    final animeCount =
        entries.where((e) => e.item.type == MediaType.anime).length;
    final mangaCount = entries.length - animeCount;

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
                  child: BannerArt(bannerId: profile.bannerId),
                ),
                Positioned(
                  top: top + 8,
                  right: 12,
                  child: Row(
                    children: [
                      _BannerButton(
                        icon: Icons.palette_outlined,
                        tooltip: 'Оформление',
                        onTap: () => _push(context, const StorePage()),
                      ),
                      const SizedBox(width: 8),
                      _BannerButton(
                        icon: Icons.settings_outlined,
                        tooltip: 'Настройки',
                        onTap: () => _push(context, const SettingsPage()),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: ProfileAvatar(
                    text: profile.avatarText,
                    frameId: profile.frameId,
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

          if (profile.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
                    onPressed: () => _push(context, const ProfileEditPage()),
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
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) => _push(
                    context,
                    v == 'store' ? const StorePage() : const SettingsPage(),
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'store', child: Text('Оформление')),
                    PopupMenuItem(value: 'settings', child: Text('Настройки')),
                  ],
                  child: const _SquareButton(icon: Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),

          // Уровень
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

          if (profile.showStats)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  _StatCard(
                    value: '${entries.length}',
                    title: 'В списках',
                    icon: Icons.bookmark_outline_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: '$completed',
                    title: 'Завершено',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    value: '${favorites.length}',
                    title: 'Избранное',
                    icon: Icons.favorite_border_rounded,
                  ),
                ],
              ),
            ),

          if (profile.showFavorites)
            _Card(
              title: 'Любимое аниме',
              onTap: () => _push(context, const FavoritesPage()),
              trailing: const Icon(Icons.chevron_right_rounded),
              child: _FavoritesRow(ids: favorites),
            ),

          if (profile.showAchievements)
            _Card(
              title: 'Достижения',
              trailing: Text(
                '$unlockedCount из ${achievements.length}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final a in achievements)
                    GestureDetector(
                      onTap: () => showInfo(
                        context,
                        '${a.title}: ${a.description}'
                            '${a.unlocked ? ' ✓' : ''}',
                      ),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: a.unlocked
                                ? a.color
                                : scheme.onSurfaceVariant
                                .withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          a.icon,
                          size: 22,
                          color: a.unlocked
                              ? a.color
                              : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Быстрые переходы.
          // Material, а не Container: ListTile рисует фон и «волну» на ближайшем Material.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.palette_outlined, color: scheme.primary),
                    title: const Text('Оформление профиля'),
                    subtitle: Text(
                      '${formatNumber(profile.points)} очков · $animeCount аниме · $mangaCount манги',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _push(context, const StorePage()),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Настройки'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _push(context, const SettingsPage()),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _Achievement {
  const _Achievement(
      this.title,
      this.description,
      this.icon,
      this.color,
      this.unlocked,
      );

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;
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

/// Блок на экране профиля с заголовком (как «Любимое аниме» в макете).
class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _FavoritesRow extends ConsumerWidget {
  const _FavoritesRow({required this.ids});

  final Set<int> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(allItemsProvider).value ?? const <MediaItem>[];
    final items = all.where((i) => ids.contains(i.id)).take(3).toList();

    if (items.isEmpty) {
      return Text(
        'Нажмите на сердечко на странице тайтла, и он появится здесь.',
        style: TextStyle(color: scheme.onSurfaceVariant),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: i < items.length
                ? GestureDetector(
              onTap: () => openDetail(context, items[i]),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CoverArt(seed: items[i].id),
                ),
              ),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.title,
    required this.icon,
  });

  final String value;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}