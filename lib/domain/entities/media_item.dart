enum MediaType { anime, manga }

enum AiringStatus { airing, finished }

/// Одно аниме или одна манга. «Чистая» модель без Flutter и JSON.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.rating,
    required this.totalUnits,
    this.studio,
    this.year,
    this.season,
    this.genres = const [],
    this.synopsis = '',
    this.status = AiringStatus.finished,
    this.popularity = 9999,
    this.votes = 0,
    this.imageUrl,
    this.posterHdUrl,
    this.tagline,
  });

  final int id;
  final String title;
  final MediaType type;
  final double rating;

  /// Всего серий (аниме) или глав (манга). 0 значит «пока неизвестно».
  final int totalUnits;
  final String? studio;
  final int? year;
  final String? season; // 'Зима', 'Весна', 'Лето', 'Осень'
  final List<String> genres;
  final String synopsis;
  final AiringStatus status;

  /// Место в рейтинге популярности: чем меньше число, тем популярнее.
  final int popularity;

  /// Сколько пользователей поставили оценку.
  final int votes;

  /// Ссылка на обложку. null значит «обложки нет», тогда рисуется градиент.
  final String? imageUrl;

  /// Постер в высоком качестве для больших карточек. null значит «нет»,
  /// тогда используется обычный imageUrl.
  final String? posterHdUrl;

  /// Короткая фраза «о чём и чем удивит» (1–2 предложения). Заполняется
  /// вручную или сервером. Если null, выжимка собирается из synopsis.
  final String? tagline;

  // Два тайтла равны, если равны id. Это нужно для FutureProvider.family.
  @override
  bool operator ==(Object other) => other is MediaItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}