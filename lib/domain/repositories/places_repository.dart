import '../entities/geo_point.dart';
import '../entities/place.dart';

/// Контракт поиска мест. Ошибки сети приходят как AppException.
abstract class PlacesRepository {
  Future<List<Place>> nearby({
    required GeoPoint center,
    required PlaceCategory category,
    int radiusMeters = 5000,
  });
}