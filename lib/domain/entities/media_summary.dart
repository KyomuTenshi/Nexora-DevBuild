import 'media_item.dart';

/// Самая длинная выжимка в символах.
const int kSummaryMaxChars = 260;

/// Короткая выжимка тайтла для страницы: своя фраза (tagline), если она есть,
/// иначе первые предложения описания. null, если рассказать нечего.
String? shortSummary(MediaItem item) {
  final custom = item.tagline?.trim();
  if (custom != null && custom.isNotEmpty) return custom;
  return digestOf(item.synopsis);
}

/// Одно или два первых предложения текста, не длиннее [kSummaryMaxChars].
/// Длинное предложение обрезается по слову с многоточием.
String? digestOf(String text) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.isEmpty) return null;

  // Предложение: всё до точки, «!», «?» или «…» (вместе с ними) либо до конца
  final sentences = [
    for (final m in RegExp(r'[^.!?…]+(?:[.!?…]+|$)').allMatches(clean))
      if (m.group(0)!.trim().isNotEmpty) m.group(0)!.trim(),
  ];
  if (sentences.isEmpty) return null;

  var result = sentences.first;
  if (sentences.length > 1) {
    final both = '$result ${sentences[1]}';
    if (both.length <= kSummaryMaxChars) result = both;
  }

  if (result.length <= kSummaryMaxChars) return result;

  // Слишком длинное: режем по границе слова
  var cut = result.substring(0, kSummaryMaxChars);
  final lastSpace = cut.lastIndexOf(' ');
  if (lastSpace > 0) cut = cut.substring(0, lastSpace);
  cut = cut.replaceFirst(RegExp(r'[\s,;:\-–—]+$'), '');
  return '$cut…';
}