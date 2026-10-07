import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/achievements_provider.dart';
import 'package:nexora/presentation/widgets/achievement_widgets.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

/// Оборачивает всё приложение и показывает плашку «Достижение получено»,
/// как в Steam. Заодно держит выдачу достижений включённой на любом экране.
class AchievementToastHost extends ConsumerWidget {
  const AchievementToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(achievementsProvider);
    final queue = ref.watch(achievementToastProvider);

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: child),
        if (queue.isNotEmpty)
        // Ключ по id: следующая плашка в очереди запускается заново
          _ToastCard(key: ValueKey(queue.first.id), index: 0),
      ],
    );
  }
}

class _ToastCard extends ConsumerStatefulWidget {
  const _ToastCard({super.key, required this.index});

  final int index;

  @override
  ConsumerState<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends ConsumerState<_ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        ref.read(achievementToastProvider.notifier).pop();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(achievementToastProvider);
    if (queue.isEmpty) return const SizedBox.shrink();
    final def = queue.first;
    final scheme = Theme.of(context).colorScheme;
    final color = rarityColor(def.rarity);
    final top = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: top + 8,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Быстро выезжает, держится, быстро уходит
          final t = _controller.value;
          final show = Curves.easeOutCubic.transform((t / 0.08).clamp(0.0, 1.0));
          final hide =
          Curves.easeInCubic.transform(((t - 0.92) / 0.08).clamp(0.0, 1.0));
          final visible = show - hide;
          return Opacity(
            opacity: visible,
            child: Transform.translate(
              offset: Offset(0, -60 * (1 - visible)),
              child: child,
            ),
          );
        },
        child: Material(
          color: scheme.surfaceContainerHighest,
          elevation: 8,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            // Нажатие закрывает плашку раньше времени
            onTap: () {
              _controller.value = 0.92;
              _controller.forward();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                children: [
                  AchievementIcon(def: def, unlocked: true, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Достижение получено',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          def.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${def.rarity.label} · +${formatNumber(def.points)} очков',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
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
      ),
    );
  }
}