import 'package:flutter/material.dart';
import 'package:nexora/core/theme/app_colors.dart';

/// Пять звёзд. Нажатие на текущую оценку снимает её.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 24,
  });

  final int value; // от 0 до 5
  final ValueChanged<int>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged == null
                ? null
                : () => onChanged!(i == value ? 0 : i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i <= value ? AppColors.star : muted,
              ),
            ),
          ),
      ],
    );
  }
}
