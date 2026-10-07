import 'package:flutter/material.dart';
import 'package:nexora/domain/entities/achievement.dart';

/// Цвет редкости, как рамки предметов в Steam.
Color rarityColor(AchievementRarity rarity) => switch (rarity) {
  AchievementRarity.common => const Color(0xFF9AA5B8),
  AchievementRarity.rare => const Color(0xFF3AA0F5),
  AchievementRarity.epic => const Color(0xFFB06CFF),
  AchievementRarity.legendary => const Color(0xFFFFC53D),
};

IconData achievementIcon(String id) => switch (id) {
  'first_step' => Icons.flag_rounded,
  'collector' => Icons.collections_bookmark_rounded,
  'archivist' => Icons.inventory_2_rounded,
  'finisher' => Icons.check_circle_rounded,
  'marathoner' => Icons.directions_run_rounded,
  'bookworm' => Icons.menu_book_rounded,
  'reader' => Icons.auto_stories_rounded,
  'librarian' => Icons.local_library_rounded,
  'viewer' => Icons.visibility_rounded,
  'otaku' => Icons.local_fire_department_rounded,
  'critic' => Icons.star_rounded,
  'judge' => Icons.gavel_rounded,
  'favorite' => Icons.favorite_rounded,
  'heart' => Icons.volunteer_activism_rounded,
  'explorer' => Icons.explore_rounded,
  'double_life' => Icons.swap_horiz_rounded,
  'perfectionist' => Icons.diamond_rounded,
  _ => Icons.emoji_events_rounded,
};

/// Круглая иконка достижения: цвет по редкости, у закрытых серая, у скрытых замок.
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    super.key,
    required this.def,
    required this.unlocked,
    this.size = 52,
  });

  final AchievementDef def;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = rarityColor(def.rarity);
    final locked = !unlocked;
    final mainColor =
    locked ? scheme.onSurfaceVariant.withValues(alpha: 0.45) : color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked ? scheme.surfaceContainerHighest : null,
        gradient: locked
            ? null
            : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.38),
            color.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: mainColor, width: 2),
      ),
      child: Icon(
        locked && def.hidden
            ? Icons.lock_outline_rounded
            : achievementIcon(def.id),
        size: size * 0.46,
        color: mainColor,
      ),
    );
  }
}