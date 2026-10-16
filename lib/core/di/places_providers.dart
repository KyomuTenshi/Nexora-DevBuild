import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/location/fake_location_repository.dart';
import 'package:nexora/data/repositories/fake_places_repository.dart';
import 'package:nexora/domain/repositories/location_repository.dart';
import 'package:nexora/domain/repositories/places_repository.dart';

/// По умолчанию «в памяти» (тесты). Настоящие реализации подставляются в main().
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return FakeLocationRepository();
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  return FakePlacesRepository();
});
