import '../entities/geo_point.dart';

/// Контракт геолокации. Сбои приходят как LocationException.
abstract class LocationRepository {
  Future<GeoPoint> currentPosition();

  /// Открывает системные настройки приложения (разрешения).
  Future<void> openAppSettings();

  /// Открывает системные настройки геолокации (включить GPS).
  Future<void> openLocationSettings();
}
