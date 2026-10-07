import 'package:flutter/material.dart';

/// Тонкая полоска прогресса. Своя, а не LinearProgressIndicator:
/// у стандартной в Material 3 есть лишние точки на конце.
class ThinProgressBar extends StatelessWidget {
  const ThinProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.trackColor,
    this.height = 4,
  });

  final double value; // от 0.0 до 1.0
  final Color color;
  final Color? trackColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: trackColor ?? Colors.black.withValues(alpha: 0.35),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                heightFactor: 1,
                child: ColoredBox(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}