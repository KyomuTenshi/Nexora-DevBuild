import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/achievement.dart';
import 'package:nexora/presentation/providers/achievements_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/widgets/achievement_widgets.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/thin_progress_bar.dart';

enum _Filter { all, unlocked, locked }

/// Все достижения: общий прогресс, очки, редкость, закрепление на витрине.
class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(achievementProgressProvider);
    final dates = ref.watch(achievementsProvider);
    final pinned = ref.watch(profileProvider.select((p) => p.pinned));

    bool isUnlocked(AchievementProgress p) => dates.containsKey(p.def.id);

    // Полученные: свежие первыми. Закрытые: ближайшие к цели первыми, скрытые в конце.
    final unlocked = all.where(isUnlocked).toList()
      ..sort((a, b) => dates[b.def.id]!.compareTo(dates[a.def.id]!));
    final locked = all.where((p) => !isUnlocked(p)).toList()
      ..sort((a, b) {
        if (a.def.hidden != b.def.hidden) return a.def.hidden ? 1 : -1;
        return b.fraction.compareTo(a.fraction);
      });

    final shown = switch (_filter) {
      _Filter.all => [...unlocked, ...locked],
      _Filter.unlocked => unlocked,
      _Filter.locked => locked,
    };
    final points = unlocked.fold<int>(0, (sum, p) => sum + p.def.points);

    return Scaffold(
      appBar: AppBar(title: const Text('Достижения')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Общий прогресс
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${unlocked.length} из ${all.length}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatNumber(points),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'очков достижений',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ThinProgressBar(
                  value: all.isEmpty ? 0 : unlocked.length / all.length,
                  color: scheme.primary,
                  trackColor: scheme.surfaceContainerHighest,
                  height: 8,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final rarity in AchievementRarity.values)
                      _RarityStat(
                        rarity: rarity,
                        got: unlocked.where((p) => p.def.rarity == rarity).length,
                        total: all.where((p) => p.def.rarity == rarity).length,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Filter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Filter.all, label: Text('Все')),
              ButtonSegment(value: _Filter.unlocked, label: Text('Полученные')),
              ButtonSegment(value: _Filter.locked, label: Text('Закрытые')),
            ],
            selected: {_filter},
            onSelectionChanged: (v) => setState(() => _filter = v.first),
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Здесь пока пусто',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          for (final p in shown) ...[
            _AchievementTile(
              progress: p,
              unlockedAt: dates[p.def.id],
              pinned: pinned.contains(p.def.id),
              onPin: () {
                final ok =
                ref.read(profileProvider.notifier).togglePin(p.def.id);
                if (!ok) {
                  showInfo(
                    context,
                    'На витрине можно закрепить не больше $kMaxPinned',
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _RarityStat extends StatelessWidget {
  const _RarityStat({
    required this.rarity,
    required this.got,
    required this.total,
  });

  final AchievementRarity rarity;
  final int got;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rarityColor(rarity),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$got/$total',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          rarity.label,
          style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.progress,
    required this.unlockedAt,
    required this.pinned,
    required this.onPin,
  });

  final AchievementProgress progress;

  /// Время получения в миллисекундах или null, если ещё не получено.
  final int? unlockedAt;
  final bool pinned;
  final VoidCallback onPin;

  static String _date(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final def = progress.def;
    final unlocked = unlockedAt != null;
    final secret = def.hidden && !unlocked;
    final color = rarityColor(def.rarity);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AchievementIcon(def: def, unlocked: unlocked, size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  secret ? 'Скрытое достижение' : def.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: unlocked ? null : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  secret
                      ? 'Условие скрыто. Пользуйтесь Nexora, и вы узнаете'
                      : def.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (!unlocked && !secret) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ThinProgressBar(
                          value: progress.fraction,
                          color: color,
                          trackColor: scheme.surfaceContainerHighest,
                          height: 6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${formatNumber(progress.current)} / ${formatNumber(def.target)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  [
                    def.rarity.label,
                    '+${formatNumber(def.points)} очков',
                    if (unlocked) 'Получено ${_date(unlockedAt!)}',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            IconButton(
              tooltip: pinned ? 'Открепить с витрины' : 'Закрепить на витрине',
              onPressed: onPin,
              icon: Icon(
                pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: pinned ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}