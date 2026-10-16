import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/core/constants/places_constants.dart';
import 'package:nexora/core/di/places_providers.dart';
import 'package:nexora/core/di/retry.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/core/theme/app_theme.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/location/fake_location_repository.dart';
import 'package:nexora/data/repositories/fake_places_repository.dart';
import 'package:nexora/data/repositories/overpass_places_repository.dart';
import 'package:nexora/domain/entities/geo_point.dart';
import 'package:nexora/domain/entities/place.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/errors/location_exception.dart';
import 'package:nexora/presentation/pages/nearby/nearby_page.dart';
import 'package:nexora/presentation/providers/nearby_provider.dart';

/// Ответ в формате Overpass (поля сокращены).
const _overpassJson = {
  'elements': [
    {
      'type': 'node',
      'id': 1,
      'lat': 43.24,
      'lon': 76.89,
      'tags': {
        'name': 'Кинотеатр А',
        'addr:street': 'Абая',
        'addr:housenumber': '10',
      },
    },
    {
      'type': 'way',
      'id': 2,
      'center': {'lat': 43.25, 'lon': 76.95},
      'tags': {'name': 'Кинотеатр Б'},
    },
    // Без названия и без координат: должны быть пропущены
    {
      'type': 'node',
      'id': 3,
      'lat': 43.3,
      'lon': 76.9,
      'tags': <String, dynamic>{},
    },
    {
      'type': 'node',
      'id': 4,
      'tags': {'name': 'Без координат'},
    },
  ],
};

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Place _place(String id, String name, double lat, double lon) => Place(
  id: id,
  name: name,
  category: PlaceCategory.cinema,
  position: GeoPoint(lat, lon),
);

void main() {
  group('GeoPoint', () {
    test('расстояние в один градус долготы на экваторе около 111 км', () {
      const a = GeoPoint(0, 0);
      const b = GeoPoint(0, 1);
      expect(a.distanceTo(b), closeTo(111195, 300));
      expect(a.distanceTo(a), 0);
    });
  });

  group('OverpassPlacesRepository', () {
    test(
      'разбирает точки и здания, пропускает записи без названия и координат',
      () async {
        late Uri requested;
        final client = MockClient((request) async {
          requested = request.url;
          return _json(_overpassJson);
        });
        final api = ApiClient(
          baseUrl: kOverpassBaseUrl,
          client: client,
          minGap: Duration.zero,
        );
        addTearDown(api.close);

        final places = await OverpassPlacesRepository(api).nearby(
          center: const GeoPoint(43.2389, 76.8897),
          category: PlaceCategory.cinema,
        );

        expect(places.map((p) => p.name), ['Кинотеатр А', 'Кинотеатр Б']);
        expect(places[0].address, 'Абая, 10');
        expect(places[1].address, isNull);
        expect(places[1].position.latitude, 43.25); // координаты из center

        final query = requested.queryParameters['data']!;
        expect(query, contains('"amenity"="cinema"'));
        expect(query, contains('around:5000,43.239,76.890'));
      },
    );

    test('ответ без списка elements даёт ParseException', () async {
      final client = MockClient((_) async => _json({'remark': 'oops'}));
      final api = ApiClient(
        baseUrl: kOverpassBaseUrl,
        client: client,
        minGap: Duration.zero,
      );
      addTearDown(api.close);

      expect(
        () =>
            OverpassPlacesRepository(api)
                .nearby(center: kDefaultCenter, category: PlaceCategory.books),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('провайдеры', () {
    test('при запрете геолокации ищем вокруг центра по умолчанию, ближайшие первыми', () async {
      final places = FakePlacesRepository(
        places: [
          _place('far', 'Далёкий', 43.30, 76.95),
          _place('near', 'Ближний', 43.24, 76.89),
        ],
      );
      final container = ProviderContainer(
        retry: noAutoRetry,
        overrides: [
          locationRepositoryProvider.overrideWithValue(
            FakeLocationRepository(problem: LocationProblem.denied),
          ),
          placesRepositoryProvider.overrideWithValue(places),
        ],
      );
      addTearDown(container.dispose);

      // Держим провайдер «под наблюдением», как это делает экран
      final subscription = container.listen(nearbyPlacesProvider, (_, _) {});
      addTearDown(subscription.close);

      final result = await container.read(nearbyPlacesProvider.future);

      expect(result.map((p) => p.name), ['Ближний', 'Далёкий']);
      expect(places.lastCenter, kDefaultCenter);
    });
  });

  group('NearbyPage', () {
    Future<void> pumpPage(
      WidgetTester tester, {
      required FakeLocationRepository location,
      required FakePlacesRepository places,
    }) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          retry: noAutoRetry,
          overrides: [
            locationRepositoryProvider.overrideWithValue(location),
            placesRepositoryProvider.overrideWithValue(places),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(AppColors.primary),
            // Вместо настоящей карты Google простой виджет
            home: NearbyPage(
              mapBuilder: (_, args) => Text('карта: ${args.places.length}'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('показывает места со своей позиции и расстоянием', (
      tester,
    ) async {
      await pumpPage(
        tester,
        location: FakeLocationRepository(
          position: const GeoPoint(43.24, 76.89),
        ),
        places: FakePlacesRepository(
          places: [_place('a', 'Кинотеатр Ближний', 43.241, 76.89)],
        ),
      );

      expect(find.text('Кинотеатр Ближний'), findsOneWidget);
      expect(find.text('карта: 1'), findsOneWidget);
      expect(find.textContaining('м'), findsWidgets); // расстояние в метрах
      expect(find.text('Нет доступа к местоположению'), findsNothing);
    });

    testWidgets('без разрешения показывает причину и всё равно ищет места', (
      tester,
    ) async {
      await pumpPage(
        tester,
        location: FakeLocationRepository(problem: LocationProblem.denied),
        places: FakePlacesRepository(
          places: [_place('a', 'Кинотеатр у центра', 43.24, 76.89)],
        ),
      );

      expect(find.text('Нет доступа к местоположению'), findsOneWidget);
      expect(find.text('Разрешить'), findsOneWidget);
      expect(find.text('Кинотеатр у центра'), findsOneWidget);
    });

    testWidgets('если выключена геолокация, кнопка открывает настройки', (
      tester,
    ) async {
      final location = FakeLocationRepository(
        problem: LocationProblem.servicesOff,
      );
      await pumpPage(
        tester,
        location: location,
        places: FakePlacesRepository(),
      );

      await tester.tap(find.text('Включить'));
      await tester.pump();

      expect(location.locationSettingsOpened, 1);
    });

    testWidgets('пустой результат показывает подсказку', (tester) async {
      await pumpPage(
        tester,
        location: FakeLocationRepository(),
        places: FakePlacesRepository(),
      );

      expect(find.text('Ничего не найдено'), findsOneWidget);
    });

    testWidgets('при сбое сети экран ошибки с «Повторить»', (tester) async {
      await pumpPage(
        tester,
        location: FakeLocationRepository(),
        places: FakePlacesRepository(error: const NetworkException('нет сети')),
      );

      expect(find.text('Нет соединения'), findsOneWidget);
      expect(find.text('Повторить'), findsOneWidget);
    });
  });
}
