import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/entities/place.dart';
import 'package:nexora/domain/repositories/places_repository.dart';

/// Поиск мест «в памяти»: по умолчанию и в тестах, без сети.
class FakePlacesRepository implements PlacesRepository {
  FakePlacesRepository({this.places = const [], this.error});

  final List<Place> places;

  /// Если задано, вместо списка выбрасывается эта ошибка.
  final Object? error;

  GeoPoint? lastCenter;
  PlaceCategory? lastCategory;

  @override
  Future<List<Place>> nearby({
    required GeoPoint center,
    required PlaceCategory category,
    int radiusMeters = 5000,
  }) async {
    lastCenter = center;
    lastCategory = category;
    final error = this.error;
    if (error != null) throw error;
    return [for (final p in places) if (p.category == category) p];
  }
}