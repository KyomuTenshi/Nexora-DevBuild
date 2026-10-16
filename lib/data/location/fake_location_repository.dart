import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/errors/location_exception.dart';
import 'package:nexora/domain/repositories/location_repository.dart';

/// Геолокация «в памяти»: по умолчанию и в тестах, без телефона.
class FakeLocationRepository implements LocationRepository {
  FakeLocationRepository({
    this.position = const GeoPoint(43.2389, 76.8897),
    this.problem,
  });

  final GeoPoint position;

  /// Если задано, вместо позиции выбрасывается эта проблема.
  final LocationProblem? problem;

  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  Future<GeoPoint> currentPosition() async {
    final problem = this.problem;
    if (problem != null) throw LocationException(problem);
    return position;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}
