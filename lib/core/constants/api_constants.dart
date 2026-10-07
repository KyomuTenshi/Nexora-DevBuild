/// Адрес Jikan (REST API MyAnimeList). Оставлен как запасной источник данных.
const String kJikanBaseUrl = 'https://api.jikan.moe/v4';

/// Адрес Kitsu: бесплатный REST API (формат JSON:API), ключ не нужен.
const String kKitsuBaseUrl = 'https://kitsu.io/api/edge';

/// В MyAnimeList у аниме и манги нумерации независимы (id 1 есть и там и там).
/// Чтобы в приложении id тайтлов не пересекались, к id манги добавляем сдвиг.
const int kMangaIdOffset = 10000000;

/// У Kitsu своя нумерация, не совпадающая с MyAnimeList (по ней сделаны
/// демо-данные). Сдвиги разводят id из Kitsu и id демо-тайтлов, иначе
/// чужой тайтл из каталога выглядел бы «уже добавленным в библиотеку».
const int kKitsuAnimeIdOffset = 20000000;
const int kKitsuMangaIdOffset = 30000000;

/// Id жанров Jikan. Ключи совпадают с kGenres.
const Map<String, int> kGenreIds = {
  'Action': 1,
  'Adventure': 2,
  'Comedy': 4,
  'Drama': 8,
  'Fantasy': 10,
  'Historical': 13,
  'Horror': 14,
  'Mecha': 18,
  'Romance': 22,
  'Sci-Fi': 24,
  'Seinen': 42,
  'Shounen': 27,
};

/// Slug категорий Kitsu для фильтра по жанру. Ключи совпадают с kGenres.
const Map<String, String> kGenreSlugs = {
  'Action': 'action',
  'Adventure': 'adventure',
  'Comedy': 'comedy',
  'Drama': 'drama',
  'Fantasy': 'fantasy',
  'Historical': 'historical',
  'Horror': 'horror',
  'Mecha': 'mecha',
  'Romance': 'romance',
  'Sci-Fi': 'science-fiction',
  'Seinen': 'seinen',
  'Shounen': 'shounen',
};