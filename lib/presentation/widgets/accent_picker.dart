import 'package:flutter/material.dart';
import 'package:nexora/core/theme/app_colors.dart';

/// Ряд цветных кружков для выбора акцентного цвета приложения.
/// Используется в настройках и на приветствии.
class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    this.size = 44,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        for (var i = 0; i < AppColors.accents.length; i++)
          Semantics(
            button: true,
            selected: i == selectedIndex,
            label: AppColors.accentNames[i],
            child: Tooltip(
              message: AppColors.accentNames[i],
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accents[i],
                    border: Border.all(
                      color: i == selectedIndex
                          ? scheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: i == selectedIndex
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
