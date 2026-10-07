import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/l10n/app_strings.dart';
import 'package:nexora/domain/entities/achievement.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/presentation/pages/profile/achievements_page.dart';
import 'package:nexora/presentation/pages/profile/favorites_page.dart';
import 'package:nexora/presentation/pages/profile/profile_screen.dart';
import 'package:nexora/presentation/pages/profile/settings_page.dart';
import 'package:nexora/presentation/pages/profile/store_page.dart';
import 'package:nexora/presentation/providers/achievements_provider.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/language_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/profile_widgets.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';

// Системные цвета в духе iOS для значков разделов
const _blue = Color(0xFF3A8DFF);
const _orange = Color(0xFFFF9F0A);
const _red = Color(0xFFFF453A);
const _green = Color(0xFF30D158);
const _purple = Color(0xFFAF52DE);
const _pink = Color(0xFFFF375F);
const _gray = Color(0xFF8E8E93);

/// Вкладка «Меню»: страница-хаб, как в мобильном Steam. Сверху карточка
/// пользователя, ниже разделы приложения одним списком.
class MenuPage extends ConsumerStatefulWidget {
  const MenuPage({super.key});

  @override
  ConsumerState<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends ConsumerState<MenuPage> {
  bool _catalogOpen = false;

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  /// Открывает каталог сразу с выбранной категорией.
  void _openCatalog(CatalogCategory category) {
    ref.read(catalogQueryProvider.notifier).setCategory(category);
    ref.read(shellTabProvider.notifier).setTab(1);
  }

  Future<void> _leaveFeedback() async {
    final s = ref.read(stringsProvider);
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _FeedbackDialog(strings: s),
    );
    if (sent == true && mounted) {
      showInfo(context, s.feedbackThanks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = ref.watch(stringsProvider);
    final profile = ref.watch(profileProvider);
    final unread = ref.watch(unreadCountProvider);
    final libraryCount = ref.watch(libraryProvider.select((m) => m.length));
    final favoritesCount = ref.watch(favoritesProvider.select((m) => m.length));
    final unlockedCount =
    ref.watch(achievementsProvider.select((m) => m.length));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            // Крупный заголовок
            Text(
              s.menuTitle,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Карточка пользователя
            _Group(
              children: [
                InkWell(
                  onTap: () => openProfile(context),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          text: profile.avatarText,
                          frameId: profile.frameId,
                          imagePath: profile.avatarPath,
                          adjust: profile.avatarAdjust,
                          level: profile.level,
                          size: 72,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.level(
                                  profile.level,
                                  formatNumber(profile.xpInLevel),
                                  formatNumber(kXpPerLevel),
                                ),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ThinProgressBar(
                                value: profile.xpInLevel / kXpPerLevel,
                                color: scheme.primary,
                                trackColor: scheme.surfaceContainerHighest,
                                height: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Основные разделы (как «Магазин», «Новости», «Библиотека» в Steam)
            _Group(
              children: [
                _MenuTile(
                  icon: Icons.grid_view_rounded,
                  color: _blue,
                  title: s.catalog,
                  onTap: () => setState(() => _catalogOpen = !_catalogOpen),
                  trailing: AnimatedRotation(
                    turns: _catalogOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                // Подпункты раскрываются плавно
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      if (_catalogOpen) ...[
                        _SubTile(
                          title: s.popular,
                          onTap: () => _openCatalog(CatalogCategory.popular),
                        ),
                        _SubTile(
                          title: s.airing,
                          onTap: () => _openCatalog(CatalogCategory.airing),
                        ),
                        _SubTile(
                          title: s.completed,
                          onTap: () => _openCatalog(CatalogCategory.completed),
                        ),
                      ],
                    ],
                  ),
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.auto_awesome_rounded,
                  color: _orange,
                  title: s.newest,
                  onTap: () => _openCatalog(CatalogCategory.newest),
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.notifications_rounded,
                  color: _red,
                  title: s.notifications,
                  badge: unread,
                  onTap: () => ref.read(shellTabProvider.notifier).setTab(3),
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.menu_book_rounded,
                  color: _green,
                  title: s.library,
                  value: '$libraryCount',
                  onTap: () => ref.read(shellTabProvider.notifier).setTab(2),
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.favorite_rounded,
                  color: _pink,
                  title: s.favorites,
                  value: '$favoritesCount',
                  onTap: () => _push(const FavoritesPage()),
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.emoji_events_rounded,
                  color: _orange,
                  title: s.achievements,
                  value: s.achievementsValue(
                    unlockedCount,
                    kAchievements.length,
                  ),
                  onTap: () => _push(const AchievementsPage()),
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.palette_rounded,
                  color: _purple,
                  title: s.pointsStore,
                  value: formatNumber(profile.points),
                  onTap: () => _push(const StorePage()),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Нижняя группа, как в Steam: настройки, отзыв, поддержка
            _Group(
              children: [
                _MenuTile(
                  icon: Icons.settings_rounded,
                  color: _gray,
                  title: s.settings,
                  onTap: () => _push(const SettingsPage()),
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.rate_review_rounded,
                  color: _orange,
                  title: s.rateApp,
                  onTap: _leaveFeedback,
                ),
                const _Line(),
                _MenuTile(
                  icon: Icons.help_rounded,
                  color: _blue,
                  title: s.support,
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Nexora',
                    applicationVersion: '1.0.0',
                    applicationLegalese: s.aboutLegalese,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Блок со скруглёнными углами (как сгруппированный список в iOS).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Разделитель, начинающийся после значка (как в настройках iOS).
class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 58, endIndent: 0);
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.value,
    this.badge = 0,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  /// Серый текст справа (например, число тайтлов).
  final String? value;

  /// Красный счётчик справа. 0 значит «не показывать».
  final int badge;

  /// Свой элемент справа вместо стрелки.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  value!,
                  style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
                ),
              ),
            trailing ??
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

/// Подпункт раскрывающегося раздела (с отступом под заголовком).
class _SubTile extends StatelessWidget {
  const _SubTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const _Line(),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(58, 11, 14, 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 15)),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Окно «Оставить отзыв». Контроллер живёт внутри окна и удаляется вместе с ним.
class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({required this.strings});

  final AppStrings strings;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;

    return AlertDialog(
      title: Text(s.feedbackTitle),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        maxLength: 300,
        decoration: InputDecoration(
          hintText: s.feedbackHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(s.send),
        ),
      ],
    );
  }
}