import 'package:flutter/material.dart';
import 'package:nexora/core/utils/russian_plural.dart';
import 'package:nexora/domain/entities/media_item.dart';

/// «серия / серии / серий» или «глава / главы / глав».
String unitWord(MediaType type, int n) => type == MediaType.anime
    ? pluralRu(n, 'серия', 'серии', 'серий')
    : pluralRu(n, 'глава', 'главы', 'глав');

/// «47 серий», «376 глав». Если длина неизвестна, пишем «?».
String unitsLabel(MediaItem item) => item.totalUnits == 0
    ? '? ${unitWord(item.type, 5)}'
    : '${item.totalUnits} ${unitWord(item.type, item.totalUnits)}';

/// «128 тыс. оценок».
String votesLabel(int votes) {
  if (votes >= 1000) return '${(votes / 1000).round()} тыс. оценок';
  return '$votes ${pluralRu(votes, 'оценка', 'оценки', 'оценок')}';
}

extension MediaTypeLabel on MediaType {
  String get label => this == MediaType.anime ? 'Аниме' : 'Манга';
  String get unitShort => this == MediaType.anime ? 'сер.' : 'гл.';
}

/// Короткое сообщение внизу экрана. Предыдущее сообщение заменяется.
void showInfo(BuildContext context, String text, {SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(text),
      action: action,
    ),
  );
}

/// 33440 -> «33 440» (тонкие пробелы между тысячами).
String formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
