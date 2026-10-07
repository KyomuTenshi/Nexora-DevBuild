import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nexora/domain/entities/image_adjust.dart';

/// Показывает файл-фото в рамке с учётом настроек пользователя:
/// сдвиг, приближение и размытие. Заполняет всю рамку, в которую вставлен.
class AdjustedImage extends StatelessWidget {
  const AdjustedImage({
    super.key,
    required this.path,
    required this.adjust,
    this.cacheWidth,
    this.fallback = const SizedBox.shrink(),
  });

  final String path;
  final ImageAdjust adjust;

  /// Ширина, до которой уменьшаем картинку при загрузке (экономит память).
  final int? cacheWidth;

  /// Что показать, если файл пропал или повреждён.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;

        Widget image = Image.file(
          File(path),
          width: w,
          height: h,
          fit: BoxFit.cover,
          // При приближении нужна более чёткая картинка
          cacheWidth:
          cacheWidth == null ? null : (cacheWidth! * adjust.scale).round(),
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => fallback,
        );

        if (adjust.hasTransform) {
          // Та же матрица, что у InteractiveViewer на экране настройки
          image = Transform(
            alignment: Alignment.topLeft,
            transform: Matrix4.translationValues(
              adjust.tx * w,
              adjust.ty * h,
              0,
            ) *
                Matrix4.diagonal3Values(adjust.scale, adjust.scale, 1),
            child: image,
          );
        }

        if (adjust.blur > 0) {
          image = ui.ImageFilter.blur(
            sigmaX: adjust.blur,
            sigmaY: adjust.blur,
          ).toWidget(image);
        }

        return ClipRect(child: SizedBox(width: w, height: h, child: image));
      },
    );
  }
}

extension on ui.ImageFilter {
  Widget toWidget(Widget child) => ImageFiltered(imageFilter: this, child: child);
}