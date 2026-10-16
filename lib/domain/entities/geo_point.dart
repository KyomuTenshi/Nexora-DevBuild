import 'dart:math' as math;

/// Точка на карте: широта и долгота. «Чистая» модель без пакетов карт.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Расстояние до другой точки в метрах (формула гаверсинусов).
  double distanceTo(GeoPoint other) {
    const earthRadius = 6371000.0;
    double rad(double degrees) => degrees * math.pi / 180;

    final dLat = rad(other.latitude - latitude);
    final dLon = rad(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) *
            math.cos(rad(other.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(a.toDouble()));
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
