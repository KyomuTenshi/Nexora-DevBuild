import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/store_catalog.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/profile_widgets.dart';

enum _StoreTab { banner, frame, badge, showcase }

/// Магазин оформления: фон, рамка аватара, значок, витрины. Покупается за очки,
/// которые начисляются за серии, главы, отзывы и завершённые тайтлы.
class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage> {
  // Выбор пока «черновик»: применяется только кнопкой «Сохранить»
  late String _banner;
  late String _frame;
  late String _badge;
  late bool _showFavorites;
  late bool _showAchievements;
  late bool _showStats;
  _StoreTab _tab = _StoreTab.banner;

  @override
  void initState() {
    super.initState();
    _loadFromProfile();
  }

  void _loadFromProfile() {
    final p = ref.read(profileProvider);
    _banner = p.bannerId;
    _frame = p.frameId;
    _badge = p.badgeId;
    _showFavorites = p.showFavorites;
    _showAchievements = p.showAchievements;
    _showStats = p.showStats;
  }

  StoreCategory? get _category => switch (_tab) {
        _StoreTab.banner => StoreCategory.banner,
        _StoreTab.frame => StoreCategory.frame,
        _StoreTab.badge => StoreCategory.badge,
        _StoreTab.showcase => null,
      };

  String _selectedIdOf(StoreCategory c) => switch (c) {
        StoreCategory.banner => _banner,
        StoreCategory.frame => _frame,
        StoreCategory.badge => _badge,
      };

  void _select(StoreItem item) {
    setState(() {
      switch (item.category) {
        case StoreCategory.banner:
          _banner = item.id;
        case StoreCategory.frame:
          _frame = item.id;
        case StoreCategory.badge:
          _badge = item.id;
      }
    });
  }

  Future<void> _onTapItem(StoreItem item) async {
    final profile = ref.read(profileProvider);
    if (profile.unlocked.contains(item.id)) {
      _select(item);
      return;
    }

    final canBuy = profile.points >= item.price;
    final buy = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Открыть «${item.title}»?'),
        content: Text(
          canBuy
              ? 'Стоимость: ${formatNumber(item.price)} очков. '
                  'У вас ${formatNumber(profile.points)}.'
              : 'Не хватает ${formatNumber(item.price - profile.points)} очков. '
                  'Смотрите серии, читайте главы и пишите отзывы.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(canBuy ? 'Отмена' : 'Понятно'),
          ),
          if (canBuy)
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Открыть'),
            ),
        ],
      ),
    );

    if (buy == true && mounted) {
      if (ref.read(profileProvider.notifier).unlock(item)) {
        _select(item);
        showInfo(context, '«${item.title}» открыто');
      }
    }
  }

  void _save() {
    ref.read(profileProvider.notifier).edit(
          (p) => p.copyWith(
            bannerId: _banner,
            frameId: _frame,
            badgeId: _badge,
            showFavorites: _showFavorites,
            showAchievements: _showAchievements,
            showStats: _showStats,
          ),
        );
    Navigator.of(context).pop();
    showInfo(context, 'Оформление сохранено');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);
    final library = ref.watch(libraryProvider).values;
    final animeCount =
        library.where((e) => e.item.type == MediaType.anime).length;
    final mangaCount = library.length - animeCount;
    final category = _category;

    final sectionTitle = switch (_tab) {
      _StoreTab.banner => 'Фоны профиля',
      _StoreTab.frame => 'Рамки аватара',
      _StoreTab.badge => 'Значки',
      _StoreTab.showcase => 'Витрины профиля',
    };

    final items = category == null ? const <StoreItem>[] : storeItemsOf(category);
    final openCount = items.where((i) => profile.unlocked.contains(i.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded,
                    size: 18, color: AppColors.star),
                const SizedBox(width: 6),
                Text(
                  '${formatNumber(profile.points)} очков',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(_loadFromProfile),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                  ),
                  child: const Text('Сбросить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 54)),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Предпросмотр: сразу видно, как будет выглядеть профиль
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 150,
              child: BannerArt(
                bannerId: _banner,
                child: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined,
                                size: 14, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Предпросмотр',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 10,
                      right: 12,
                      child: Row(
                        children: [
                          ProfileAvatar(
                            text: profile.avatarText,
                            frameId: _frame,
                            level: profile.level,
                            size: 84,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${storeItemById(_badge).title} · $animeCount аниме · $mangaCount манги',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
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
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TabChip(
                  icon: Icons.image_outlined,
                  label: 'Фон',
                  selected: _tab == _StoreTab.banner,
                  onTap: () => setState(() => _tab = _StoreTab.banner),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  icon: Icons.tag_rounded,
                  label: 'Рамка',
                  selected: _tab == _StoreTab.frame,
                  onTap: () => setState(() => _tab = _StoreTab.frame),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  icon: Icons.shield_outlined,
                  label: 'Значок',
                  selected: _tab == _StoreTab.badge,
                  onTap: () => setState(() => _tab = _StoreTab.badge),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  icon: Icons.dashboard_outlined,
                  label: 'Витрины',
                  selected: _tab == _StoreTab.showcase,
                  onTap: () => setState(() => _tab = _StoreTab.showcase),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (category != null)
                Text(
                  '$openCount из ${items.length} открыто',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (category != null)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 172,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return _StoreTile(
                  item: item,
                  selected: _selectedIdOf(category) == item.id,
                  unlocked: profile.unlocked.contains(item.id),
                  avatarText: profile.avatarText,
                  onTap: () => _onTapItem(item),
                );
              },
            )
          else
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Статистика'),
                    subtitle: const Text('Списки, завершённые, избранное'),
                    value: _showStats,
                    onChanged: (v) => setState(() => _showStats = v),
                  ),
                  SwitchListTile(
                    title: const Text('Любимое аниме'),
                    value: _showFavorites,
                    onChanged: (v) => setState(() => _showFavorites = v),
                  ),
                  SwitchListTile(
                    title: const Text('Достижения'),
                    value: _showAchievements,
                    onChanged: (v) => setState(() => _showAchievements = v),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: AppColors.star),
                    SizedBox(width: 8),
                    Text(
                      'Как получить очки',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '+10 за серию · +20 за главу · +50 за отзыв · +100 за завершённый тайтл',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
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

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : scheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.item,
    required this.selected,
    required this.unlocked,
    required this.avatarText,
    required this.onTap,
  });

  final StoreItem item;
  final bool selected;
  final bool unlocked;
  final String avatarText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget preview = switch (item.category) {
      StoreCategory.banner => BannerArt(bannerId: item.id),
      StoreCategory.frame => ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: ProfileAvatar(
              text: avatarText,
              frameId: item.id,
              size: 84,
            ),
          ),
        ),
      StoreCategory.badge => ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    };

    final String caption;
    final Color captionColor;
    if (selected) {
      caption = 'Выбрано';
      captionColor = scheme.primary;
    } else if (unlocked) {
      caption = 'Открыто';
      captionColor = AppColors.success;
    } else {
      caption = '${formatNumber(item.price)} очков';
      captionColor = AppColors.star;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    preview,
                    if (!unlocked)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        child: const Center(
                          child: Icon(Icons.lock_outline_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 18, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          Text(
            caption,
            style: TextStyle(fontSize: 12.5, color: captionColor),
          ),
        ],
      ),
    );
  }
}
