import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';

/// Перевод наших моделей в JSON и обратно для хранения на диске.
/// Модели остаются «чистыми» (без JSON), а вся работа с форматом лежит здесь.

Map<String, dynamic> mediaItemToJson(MediaItem item) => {
  'id': item.id,
  'title': item.title,
  'type': item.type.name,
  'rating': item.rating,
  'totalUnits': item.totalUnits,
  'studio': item.studio,
  'year': item.year,
  'season': item.season,
  'genres': item.genres,
  'synopsis': item.synopsis,
  'status': item.status.name,
  'popularity': item.popularity,
  'votes': item.votes,
  'imageUrl': item.imageUrl,
  'posterHdUrl': item.posterHdUrl,
  'tagline': item.tagline,
};

/// Если в данных нет обязательного поля или тип другой, бросает ошибку.
/// Тот, кто читает хранилище, пропускает такую запись, а не падает.
MediaItem mediaItemFromJson(Map<String, dynamic> json) {
  return MediaItem(
    id: json['id'] as int,
    title: json['title'] as String,
    type: MediaType.values.byName(json['type'] as String),
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    totalUnits: json['totalUnits'] as int? ?? 0,
    studio: json['studio'] as String?,
    year: json['year'] as int?,
    season: json['season'] as String?,
    genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? const [],
    synopsis: json['synopsis'] as String? ?? '',
    status: AiringStatus.values.byName(json['status'] as String? ?? 'finished'),
    popularity: json['popularity'] as int? ?? 9999,
    votes: json['votes'] as int? ?? 0,
    imageUrl: json['imageUrl'] as String?,
    posterHdUrl: json['posterHdUrl'] as String?,
    tagline: json['tagline'] as String?,
  );
}

Map<String, dynamic> libraryEntryToJson(LibraryEntry entry) => {
  'item': mediaItemToJson(entry.item),
  'status': entry.status.name,
  'progress': entry.progress,
  'updatedAt': entry.updatedAt.millisecondsSinceEpoch,
};

LibraryEntry libraryEntryFromJson(Map<String, dynamic> json) {
  return LibraryEntry(
    item: mediaItemFromJson(json['item'] as Map<String, dynamic>),
    status: LibraryStatus.values.byName(json['status'] as String),
    progress: json['progress'] as int? ?? 0,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
  );
}