import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/entities/place.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/places_repository.dart';

/// Поиск мест рядом через Overpass API (данные OpenStreetMap).
/// Запрос и ответ идут через общий ApiClient: те же таймауты, ограничение
/// частоты, перевод ошибок и offline-кэш, что и у каталога.
class OverpassPlacesRepository implements PlacesRepository {
  OverpassPlacesRepository(this._api);

  final ApiClient _api;

  /// Теги OpenStreetMap для каждой категории.
  static const Map<PlaceCategory, List<String>> _filters = {
    PlaceCategory.cinema: ['"amenity"="cinema"'],
    PlaceCategory.books: ['"shop"="books"'],
    PlaceCategory.games: ['"shop"="games"', '"shop"="video_games"'],
  };

  @override
  Future<List<Place>> nearby({
    required GeoPoint center,
    required PlaceCategory category,
    int radiusMeters = 5000,
  }) async {
    // Координаты округляем до ~100 м: так повторный запрос из того же места
    // берётся из кэша, а точное положение не уходит на сервер.
    final lat = center.latitude.toStringAsFixed(3);
    final lon = center.longitude.toStringAsFixed(3);
    final around = '(around:$radiusMeters,$lat,$lon)';

    final parts = StringBuffer();
    for (final filter in _filters[category]!) {
      // node — точка, way — здание (для него просим центр)
      parts.write('node[$filter]$around;way[$filter]$around;');
    }
    final query = '[out:json][timeout:15];($parts);out center 50;';

    final json = await _api.getJson('/interpreter', {'data': query});
    final elements = json['elements'];
    if (elements is! List) {
      throw const ParseException('Overpass: в ответе нет списка elements');
    }

    final result = <Place>[];
    for (final element in elements) {
      try {
        final place = _parse(element as Map<String, dynamic>, category);
        if (place != null) result.add(place);
      } catch (_) {
        // Одна битая запись не должна ломать весь список
      }
    }
    return result;
  }

  Place? _parse(Map<String, dynamic> element, PlaceCategory category) {
    final tags = element['tags'];
    if (tags is! Map) return null;

    final name = (tags['name:ru'] ?? tags['name']) as String?;
    if (name == null || name.trim().isEmpty) return null;

    // У точки координаты лежат в самой записи, у здания — в center
    final center = element['center'];
    final lat =
        (element['lat'] ?? (center is Map ? center['lat'] : null)) as num?;
    final lon =
        (element['lon'] ?? (center is Map ? center['lon'] : null)) as num?;
    if (lat == null || lon == null) return null;

    final street = tags['addr:street'] as String?;
    final house = tags['addr:housenumber'] as String?;
    final address = [street, house].whereType<String>().join(', ');

    return Place(
      id: '${element['type']}/${element['id']}',
      name: name.trim(),
      category: category,
      position: GeoPoint(lat.toDouble(), lon.toDouble()),
      address: address.isEmpty ? null : address,
    );
  }
}
