import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';

/// DTO (Data Transfer Object): форма данных ровно такая, как их отдаёт Kitsu.
/// Kitsu использует формат JSON:API: у записи есть `id`, `attributes` и
/// `relationships`, а связанные объекты (категории) лежат в списке `included`.
/// Приложение работает с MediaItem, а этот класс лишь переводит JSON в него.
class KitsuMediaDto {
  const KitsuMediaDto({
    required this.id,
    required this.title,
    this.imageUrl,
    this.posterHdUrl,
    this.averageRating,
    this.userCount,
    this.popularityRank,
    this.episodes,
    this.chapters,
    this.status,
    this.startDate,
    this.synopsis,
    this.genres = const [],
  });

  final int id;
  final String title;
  final String? imageUrl;

  /// Постер в высоком качестве (original) для больших карточек.
  final String? posterHdUrl;

  /// У Kitsu оценка в процентах (82.5 значит 8.25 из 10).
  final double? averageRating;
  final int? userCount;
  final int? popularityRank;
  final int? episodes;
  final int? chapters;
  final String? status;

  /// Дата начала в формате «1999-10-20».
  final String? startDate;
  final String? synopsis;
  final List<String> genres;

  /// [categories] — словарь id категории -> название, собранный из `included`.
  factory KitsuMediaDto.fromResource(
      Map<String, dynamic> json,
      Map<String, String> categories,
      ) {
    final id = int.tryParse('${json['id']}');
    final attributes = json['attributes'];
    if (id == null || attributes is! Map) {
      throw const ParseException('В записи нет id или attributes');
    }

    final titles = attributes['titles'];
    final title = _text(titles is Map ? titles['en'] : null) ??
        _text(attributes['canonicalTitle']) ??
        _text(titles is Map ? titles['en_jp'] : null);
    if (title == null) {
      throw const ParseException('В записи нет названия');
    }

    return KitsuMediaDto(
      id: id,
      title: title,
      imageUrl: _text(_dig(attributes, ['posterImage', 'large'])) ??
          _text(_dig(attributes, ['posterImage', 'original'])) ??
          _text(_dig(attributes, ['posterImage', 'medium'])),
      posterHdUrl: _text(_dig(attributes, ['posterImage', 'original'])) ??
          _text(_dig(attributes, ['posterImage', 'large'])),
      averageRating: double.tryParse('${attributes['averageRating']}'),
      userCount: _int(attributes['userCount']),
      popularityRank: _int(attributes['popularityRank']),
      episodes: _int(attributes['episodeCount']),
      chapters: _int(attributes['chapterCount']),
      status: _text(attributes['status']),
      startDate: _text(attributes['startDate']),
      synopsis: _text(attributes['synopsis']),
      genres: _genres(json, categories),
    );
  }

  MediaItem toDomain(MediaType type) {
    final isManga = type == MediaType.manga;
    return MediaItem(
      id: (isManga ? kKitsuMangaIdOffset : kKitsuAnimeIdOffset) + id,
      title: title,
      type: type,
      rating: averageRating == null ? 0 : averageRating! / 10,
      totalUnits: (isManga ? chapters : episodes) ?? 0,
      year: _year,
      season: isManga ? null : _season,
      genres: genres,
      synopsis: _cleanSynopsis(synopsis),
      status: status == 'current' ? AiringStatus.airing : AiringStatus.finished,
      popularity: popularityRank ?? 99999,
      votes: userCount ?? 0,
      imageUrl: imageUrl,
      posterHdUrl: posterHdUrl,
    );
  }

  int? get _year {
    final date = startDate;
    if (date == null || date.length < 4) return null;
    return int.tryParse(date.substring(0, 4));
  }

  /// Сезон считаем по месяцу начала показа.
  String? get _season {
    final date = startDate;
    if (date == null || date.length < 7) return null;
    final month = int.tryParse(date.substring(5, 7));
    if (month == null) return null;
    return switch (month) {
      12 || 1 || 2 => 'Зима',
      3 || 4 || 5 => 'Весна',
      6 || 7 || 8 => 'Лето',
      _ => 'Осень',
    };
  }

  /// Названия, которые у Kitsu пишутся иначе, чем в нашем списке жанров.
  static const Map<String, String> _genreAliases = {
    'Science Fiction': 'Sci-Fi',
  };

  /// Жанры тайтла. Известные нам (из kGenreSlugs) идут первыми, остальные
  /// после них. Всего берём не больше шести, чтобы не заполнять экран тегами.
  static List<String> _genres(
      Map<String, dynamic> json,
      Map<String, String> categories,
      ) {
    final data = _dig(json, ['relationships', 'categories', 'data']);
    if (data is! List) return const [];

    final names = <String>[];
    for (final ref in data) {
      if (ref is! Map) continue;
      final name = categories['${ref['id']}'];
      if (name == null) continue;
      final normalized = _genreAliases[name] ?? name;
      if (!names.contains(normalized)) names.add(normalized);
    }

    final known = names.where(kGenreSlugs.containsKey);
    final other = names.where((n) => !kGenreSlugs.containsKey(n));
    return [...known, ...other].take(6).toList();
  }

  /// Kitsu дописывает в конец описания источник: «(Source: ...)».
  static String _cleanSynopsis(String? text) {
    if (text == null) return '';
    return text
        .replaceAll(
      RegExp(r'\s*[\(\[](Source|Written by)[^\)\]]*[\)\]]\s*$'),
      '',
    )
        .replaceAll('\r\n', '\n')
        .trim();
  }
}

/// Разбор страницы списка: {"data": [...], "included": [...]}.
List<KitsuMediaDto> parseKitsuList(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is! List) {
    throw const ParseException('В ответе нет списка data');
  }

  // Названия категорий лежат отдельно, в `included`
  final categories = <String, String>{};
  final included = json['included'];
  if (included is List) {
    for (final entry in included) {
      if (entry is! Map || entry['type'] != 'categories') continue;
      final title = _text(_dig(entry, ['attributes', 'title']));
      if (title != null) categories['${entry['id']}'] = title;
    }
  }

  final result = <KitsuMediaDto>[];
  for (final entry in data) {
    if (entry is! Map<String, dynamic>) continue;
    try {
      result.add(KitsuMediaDto.fromResource(entry, categories));
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

Object? _dig(Object? json, List<String> path) {
  Object? current = json;
  for (final key in path) {
    if (current is! Map) return null;
    current = current[key];
  }
  return current;
}