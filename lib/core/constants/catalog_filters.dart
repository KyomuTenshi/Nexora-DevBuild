/// Варианты для фильтров каталога. Позже жанры и студии придут из API.
const List<String> kGenres = [
  'Action', 'Adventure', 'Comedy', 'Drama', 'Fantasy', 'Historical',
  'Horror', 'Mecha', 'Romance', 'Sci-Fi', 'Seinen', 'Shounen',
];

const List<String> kSeasons = ['Зима', 'Весна', 'Лето', 'Осень'];

const List<String> kStudios = [
  'A-1 Pictures', 'CloverWorks', 'Fuji TV', 'Madhouse', 'MAPPA',
  'Science SARU', 'Sunrise', 'Trigger', 'ufotable', 'Wit Studio',
];

/// Последние 30 лет, считаются от текущей даты.
final List<String> kYears =
List.generate(30, (i) => '${DateTime.now().year - i}');