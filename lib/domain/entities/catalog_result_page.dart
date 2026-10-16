import 'media_item.dart';

/// Одна страница результатов каталога.
class CatalogResultPage {
  const CatalogResultPage({required this.items, required this.hasMore});

  final List<MediaItem> items;

  /// Есть ли смысл просить следующую страницу.
  final bool hasMore;
}