import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/domain/entities/image_adjust.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

void main() {
  group('ImageAdjust', () {
    test('по умолчанию фото не двигается и не меняется', () {
      const adjust = ImageAdjust();
      expect(adjust.hasTransform, isFalse);
      expect(adjust.scale, 1);
      expect(adjust.dim, 0);
      expect(adjust.blur, 0);
    });

    test('сохраняется в JSON и читается обратно', () {
      const adjust = ImageAdjust(scale: 2.5, tx: -0.4, ty: -0.2, dim: 0.3, blur: 5);
      final restored = ImageAdjust.fromJson(
        jsonDecode(jsonEncode(adjust.toJson())) as Map<String, dynamic>,
      );
      expect(restored, adjust);
      expect(restored.hasTransform, isTrue);
    });

    test('мусор и выход за границы заменяются допустимыми значениями', () {
      final adjust = ImageAdjust.fromJson({
        'scale': 99,
        'dim': -1,
        'blur': 'много',
        'tx': null,
      });
      expect(adjust.scale, ImageAdjust.maxScale);
      expect(adjust.dim, 0);
      expect(adjust.blur, 0);
      expect(adjust.tx, 0);
    });
  });

  group('Профиль и настройка фото', () {
    test('настройки фото сохраняются вместе с профилем', () {
      final profile = ProfileState.initial().copyWith(
        avatarPath: '/photo/a.jpg',
        avatarAdjust: const ImageAdjust(scale: 2, tx: -0.5),
        bannerAdjust: const ImageAdjust(dim: 0.4, blur: 6),
      );
      final restored = ProfileState.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
      );

      expect(restored.avatarPath, '/photo/a.jpg');
      expect(restored.avatarAdjust.scale, 2);
      expect(restored.bannerAdjust.blur, 6);
    });

    test('профиль, сохранённый раньше без настроек, открывается', () {
      final restored = ProfileState.fromJson({'name': 'Аня'});
      expect(restored.name, 'Аня');
      expect(restored.avatarAdjust, const ImageAdjust());
      expect(restored.bannerAdjust.hasTransform, isFalse);
    });
  });
}