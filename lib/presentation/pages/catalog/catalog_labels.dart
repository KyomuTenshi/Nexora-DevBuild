import 'package:nexora/domain/entities/catalog_query.dart';

extension CatalogCategoryLabel on CatalogCategory {
  String get label => switch (this) {
    CatalogCategory.popular => 'Популярное',
    CatalogCategory.newest => 'Новинки',
    CatalogCategory.airing => 'Сейчас выходит',
    CatalogCategory.completed => 'Завершённые',
  };
}

extension CatalogSortLabel on CatalogSort {
  String get label => switch (this) {
    CatalogSort.popularity => 'По популярности',
    CatalogSort.rating => 'По рейтингу',
    CatalogSort.title => 'По названию',
  };
}