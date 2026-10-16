import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/places_constants.dart';
import 'package:nexora/core/di/places_providers.dart';
import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/entities/place.dart';

/// Где сейчас пользователь. Если определить не вышло, провайдер в состоянии
/// ошибки (LocationException): экран по ней покажет причину и действие.
final locationProvider = FutureProvider<GeoPoint>((ref) {
  return ref.watch(locationRepositoryProvider).currentPosition();
});

/// Вокруг какой точки искать: своя позиция или центр по умолчанию, если
/// геолокация недоступна. Ждёт ответ геолокации, чтобы не искать дважды.
final nearbyCenterProvider = FutureProvider<GeoPoint>((ref) async {
  try {
    return await ref.watch(locationProvider.future);
  } catch (_) {
    return kDefaultCenter;
  }
});

class PlaceCategoryNotifier extends Notifier<PlaceCategory> {
  @override
  PlaceCategory build() => PlaceCategory.cinema;

  void select(PlaceCategory category) => state = category;
}

final placeCategoryProvider =
NotifierProvider<PlaceCategoryNotifier, PlaceCategory>(
  PlaceCategoryNotifier.new,
);

/// Места вокруг центра в выбранной категории, ближайшие первыми.
final nearbyPlacesProvider = FutureProvider.autoDispose<List<Place>>((ref) async {
  final center = await ref.watch(nearbyCenterProvider.future);
  final category = ref.watch(placeCategoryProvider);

  final places = await ref.watch(placesRepositoryProvider).nearby(
    center: center,
    category: category,
    radiusMeters: kNearbyRadiusMeters,
  );

  return [...places]..sort(
        (a, b) => center
        .distanceTo(a.position)
        .compareTo(center.distanceTo(b.position)),
  );
});