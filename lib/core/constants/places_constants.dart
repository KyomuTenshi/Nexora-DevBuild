import 'package:nexora/domain/entities/geo_point.dart';

/// Центр карты, когда местоположение определить не удалось: Алматы.
const GeoPoint kDefaultCenter = GeoPoint(43.2389, 76.8897);

/// Радиус поиска мест рядом, в метрах.
const int kNearbyRadiusMeters = 5000;
