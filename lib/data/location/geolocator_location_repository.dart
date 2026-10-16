import 'package:geolocator/geolocator.dart';
import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/errors/location_exception.dart';
import 'package:nexora/domain/repositories/location_repository.dart';

/// Настоящая геолокация телефона (пакет geolocator).
class GeolocatorLocationRepository implements LocationRepository {
  @override
  Future<GeoPoint> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationProblem.servicesOff);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(LocationProblem.denied);
      case LocationPermission.deniedForever:
        throw const LocationException(LocationProblem.deniedForever);
      case LocationPermission.unableToDetermine:
        throw const LocationException(LocationProblem.unavailable);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } catch (_) {
      throw const LocationException(LocationProblem.unavailable);
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
