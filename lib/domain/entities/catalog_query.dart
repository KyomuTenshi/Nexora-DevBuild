enum CatalogCategory { popular, newest, airing, completed }

enum CatalogSort { popularity, rating, title }

/// Все параметры каталога одним объектом: текст, вкладка, фильтры, сортировка.
class CatalogQuery {
  const CatalogQuery({
    this.text = '',
    this.category = CatalogCategory.popular,
    this.sort = CatalogSort.popularity,
    this.genre,
    this.year,
    this.studio,
    this.season,
  });

  final String text;
  final CatalogCategory category;
  final CatalogSort sort;
  final String? genre;
  final int? year;
  final String? studio;
  final String? season;

  bool get hasFilters =>
      genre != null || year != null || studio != null || season != null;

  /// copyWith создаёт копию с изменёнными полями (объект неизменяемый).
  /// Для nullable-полей передаём функцию: genre: () => null значит «сбросить»,
  /// а если параметр не передан, значение остаётся прежним.
  CatalogQuery copyWith({
    String? text,
    CatalogCategory? category,
    CatalogSort? sort,
    String? Function()? genre,
    int? Function()? year,
    String? Function()? studio,
    String? Function()? season,
  }) {
    return CatalogQuery(
      text: text ?? this.text,
      category: category ?? this.category,
      sort: sort ?? this.sort,
      genre: genre != null ? genre() : this.genre,
      year: year != null ? year() : this.year,
      studio: studio != null ? studio() : this.studio,
      season: season != null ? season() : this.season,
    );
  }
}