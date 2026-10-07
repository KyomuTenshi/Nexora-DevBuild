/// Как показывать своё фото в рамке: приближение, сдвиг, затемнение, размытие.
/// Сдвиг хранится долей от размера рамки, поэтому одинаково работает
/// в рамках разного размера. Чистая модель без Flutter.
class ImageAdjust {
  const ImageAdjust({
    this.scale = 1,
    this.tx = 0,
    this.ty = 0,
    this.dim = 0,
    this.blur = 0,
  });

  static const double maxScale = 4;
  static const double maxDim = 0.8;
  static const double maxBlur = 16;

  /// Приближение: от 1 (фото целиком в рамке) до [maxScale].
  final double scale;

  /// Сдвиг по горизонтали и вертикали в долях от ширины и высоты рамки.
  final double tx;
  final double ty;

  /// Затемнение от 0 до [maxDim].
  final double dim;

  /// Размытие от 0 до [maxBlur].
  final double blur;

  /// Нужно ли вообще двигать и приближать фото.
  bool get hasTransform => scale != 1 || tx != 0 || ty != 0;

  ImageAdjust copyWith({
    double? scale,
    double? tx,
    double? ty,
    double? dim,
    double? blur,
  }) {
    return ImageAdjust(
      scale: scale ?? this.scale,
      tx: tx ?? this.tx,
      ty: ty ?? this.ty,
      dim: dim ?? this.dim,
      blur: blur ?? this.blur,
    );
  }

  Map<String, dynamic> toJson() => {
    'scale': scale,
    'tx': tx,
    'ty': ty,
    'dim': dim,
    'blur': blur,
  };

  /// Читаем осторожно: мусор и выход за границы заменяются допустимым значением.
  factory ImageAdjust.fromJson(Map<String, dynamic> json) {
    double read(String key, double fallback, double min, double max) {
      final value = json[key];
      if (value is! num) return fallback;
      return value.toDouble().clamp(min, max).toDouble();
    }

    return ImageAdjust(
      scale: read('scale', 1, 1, maxScale),
      tx: read('tx', 0, -maxScale, maxScale),
      ty: read('ty', 0, -maxScale, maxScale),
      dim: read('dim', 0, 0, maxDim),
      blur: read('blur', 0, 0, maxBlur),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ImageAdjust &&
          other.scale == scale &&
          other.tx == tx &&
          other.ty == ty &&
          other.dim == dim &&
          other.blur == blur;

  @override
  int get hashCode => Object.hash(scale, tx, ty, dim, blur);
}