import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF7C5CFF);
  static const Color star = Color(0xFFFFC53D);
  static const Color success = Color(0xFF35D07F);
  static const Color pink = Color(0xFFFF5C8A);

  static const Color darkBackground = Color(0xFF0E0E14);
  static const Color darkSurface = Color(0xFF181822);
  static const Color darkSurfaceHigh = Color(0xFF252533);
  static const Color darkText = Color(0xFFF5F5FA);
  static const Color darkTextSecondary = Color(0xFF8E8EA3);

  static const Color lightBackground = Color(0xFFF6F5FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFECEAF6);
  static const Color lightText = Color(0xFF14141F);
  static const Color lightTextSecondary = Color(0xFF6B6B80);

  /// Акцентные цвета, которые пользователь выбирает в настройках.
  static const List<Color> accents = [
    Color(0xFF7C5CFF),
    Color(0xFFFF5C8A),
    Color(0xFF3AA0F5),
    Color(0xFF2FD08A),
    Color(0xFFFFB347),
    Color(0xFF2CCFC0),
  ];

  static const List<String> accentNames = [
    'Фиолетовый',
    'Розовый',
    'Синий',
    'Зелёный',
    'Оранжевый',
    'Бирюзовый',
  ];
}
