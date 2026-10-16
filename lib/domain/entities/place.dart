import 'geo_point.dart';

/// Какие места ищем рядом.
enum PlaceCategory { cinema, books, games }

/// Место на карте: кинотеатр, магазин и т. п.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    this.address,
  });

  final String id;
  final String name;
  final PlaceCategory category;
  final GeoPoint position;
  final String? address;
}