import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';

/// DTO (Data Transfer Object): форма данных ровно такая, как их отдаёт API.
/// Приложение работает с MediaItem, а этот класс лишь переводит JSON в него.
/// Если API изменится, правки нужны только здесь.
class JikanMediaDto {
  const JikanMediaDto({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.score,
    this.scoredBy,
    this.popularity,
    this.episodes,
    this.chapters,
    this.status,
    this.year,
    this.season,
    this.synopsis,
    this.studio,
    this.genres = const [],
  });

  final int malId;
  final String title;
  final String? imageUrl;
  final double? score;
  final int? scoredBy;
  final int? popularity;
  final int? episodes;
  final int? chapters;
  final String? status;
  final int? year;
  final String? season;
  final String? synopsis;
  final String? studio;
  final List<String> genres;

  factory JikanMediaDto.fromJson(Map<String, dynamic> json) {
    final malId = json['mal_id'];
    final title = _text(json['title_english']) ?? _text(json['title']);
    if (malId is! int || title == null) {
      throw const ParseException('В записи нет mal_id или названия');
    }

    final studios = _names(json['studios']);
    return JikanMediaDto(
      malId: malId,
      title: title,
      imageUrl: _text(_dig(json, ['images', 'jpg', 'large_image_url'])) ??
          _text(_dig(json, ['images', 'jpg', 'image_url'])),
      score: _double(json['score']),
      scoredBy: _int(json['scored_by']),
      popularity: _int(json['popularity']),
      episodes: _int(json['episodes']),
      chapters: _int(json['chapters']),
      status: _text(json['status']),
      year: _int(json['year']) ??
          _int(_dig(json, ['aired', 'prop', 'from', 'year'])) ??
          _int(_dig(json, ['published', 'prop', 'from', 'year'])),
      season: _text(json['season']),
      synopsis: _text(json['synopsis']),
      studio: studios.isEmpty ? null : studios.first,
      // Жанры, темы и аудитория (Shounen, Seinen) для нас одно и то же
      genres: {
        ..._names(json['genres']),
        ..._names(json['themes']),
        ..._names(json['demographics']),
      }.toList(),
    );
  }

  MediaItem toDomain(MediaType type) {
    final isManga = type == MediaType.manga;
    return MediaItem(
      id: isManga ? kMangaIdOffset + malId : malId,
      title: title,
      type: type,
      rating: score ?? 0,
      totalUnits: (isManga ? chapters : episodes) ?? 0,
      studio: studio,
      year: year,
      season: _seasonRu(season),
      genres: genres,
      synopsis: _cleanSynopsis(synopsis),
      status: _isOngoing(status) ? AiringStatus.airing : AiringStatus.finished,
      popularity: popularity ?? 99999,
      votes: scoredBy ?? 0,
      imageUrl: imageUrl,
    );
  }

  static bool _isOngoing(String? status) =>
      status == 'Currently Airing' || status == 'Publishing';

  static String? _seasonRu(String? season) => switch (season) {
    'winter' => 'Зима',
    'spring' => 'Весна',
    'summer' => 'Лето',
    'fall' => 'Осень',
    _ => null,
  };

  /// MyAnimeList дописывает в конец описания служебную пометку.
  static String _cleanSynopsis(String? text) {
    if (text == null) return '';
    return text.replaceAll(RegExp(r'\s*\[Written by[^\]]*\]\s*$'), '').trim();
  }
}

/// Разбор страницы списка: {"data": [ {...}, {...} ]}.
List<JikanMediaDto> parseMediaList(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! List) {
    throw const ParseException('В ответе нет списка data');
  }
  final result = <JikanMediaDto>[];
  for (final entry in data) {
    if (entry is! Map<String, dynamic>) continue;
    try {
      result.add(JikanMediaDto.fromJson(entry));
    } on ParseException {
      // Одна «битая» запись не должна ломать весь список
      continue;
    }
  }
  return result;
}

// --- безопасные помощники разбора: на неожиданный тип возвращают null ---

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _int(Object? value) => value is num ? value.toInt() : null;

double? _double(Object? value) => value is num ? value.toDouble() : null;

Object? _dig(Object? json, List<String> path) {
  Object? current = json;
  for (final key in path) {
    if (current is! Map) return null;
    current = current[key];
  }
  return current;
}

List<String> _names(Object? value) {
  if (value is! List) return const [];
  return [
    for (final e in value)
      if (e is Map && _text(e['name']) != null) _text(e['name'])!,
  ];
}