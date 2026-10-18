import 'package:flutter/material.dart';
import 'package:nexora/core/theme/app_colors.dart';

/// Логотип Nexora: скруглённый квадрат с градиентом от акцентного цвета.
/// Один и тот же знак на приветствии и на экране входа.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 112});

  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.285),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, AppColors.pink],
        ),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size * 0.48,
        color: Colors.white,
      ),
    );
  }
}
