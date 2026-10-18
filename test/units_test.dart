import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/dto/kitsu_dto.dart';
import 'package:nexora/data/repositories/kitsu_units_repository.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_unit.dart';
import 'package:nexora/domain/repositories/units_repository.dart';
import 'package:nexora/presentation/providers/units_provider.dart';

const _episodesJson = {
  'data': [
    {
      'id': '1',
      'type': 'episodes',
      'attributes': {
        'number': 1,
        'canonicalTitle': 'Romance Dawn',
        'titles': {'en_jp': 'Romance Dawn'},
        'airdate': '1999-10-20',
        'length': 24,
        'thumbnail': {'original': 'https://example.com/1.jpg'},
      },
    },
    // Спецвыпуск без номера пропускаем
    {
      'id': '2',
      'type': 'episodes',
      'attributes': {'number': null, 'canonicalTitle': 'Special'},
    },
    {
      'id': '3',
      'type': 'episodes',
      'attributes': {'number': 2},
    },
  ],
  'meta': {'count': 1100},
};

const _chaptersJson = {
  'data': [
    {
      'id': '10',
      'type': 'chapters',
      'attributes': {'number': 5, 'volumeNumber': 1, 'published': '1989-08-25'},
    },
  ],
  'meta': {'count': 1},
};

MediaItem _item(int id, {MediaType type = MediaType.anime, int units = 0}) =>
    MediaItem(id: id, title: 'Тайтл', type: type, rating: 8, totalUnits: units);

/// Отдаёт страницы по [kUnitsPageSize] записей; у каждых десяти глав свой том.
class _FakeUnits implements UnitsRepository {
  _FakeUnits(this.total);

  final int total;
  int requests = 0;

  @override
  Future<UnitsPage> getUnits(MediaItem item, {required int page}) async {
    requests++;
    final start = page * kUnitsPageSize;
    final end = math.min(total, start + kUnitsPageSize);
    return UnitsPage(
      items: [
        for (var n = start + 1; n <= end; n++)
          MediaUnit(number: n, title: 'Эп $n', volume: (n - 1) ~/ 10 + 1),
      ],
      total: total,
    );
  }
}

ProviderContainer _container(UnitsRepository repo) {
  final container = ProviderContainer(
    overrides: [unitsRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('parseKitsuUnits', () {
    test('читает серии и пропускает записи без номера', () {
      final page = parseKitsuUnits(_episodesJson);

      expect(page.total, 1100);
      expect(page.items.map((u) => u.number), [1, 2]);
      final first = page.items.first;
      expect(first.title, 'Romance Dawn');
      expect(first.minutes, 24);
      expect(first.date, '1999-10-20');
      expect(first.thumbnailUrl, 'https://example.com/1.jpg');
      expect(page.items.last.title, isNull);
    });

    test('читает том и дату выхода главы', () {
      final chapter = parseKitsuUnits(_chaptersJson).items.single;

      expect(chapter.number, 5);
      expect(chapter.volume, 1);
      expect(chapter.date, '1989-08-25');
    });

    test('на пустой ответ отдаёт пустую страницу', () {
      final page = parseKitsuUnits({});
      expect(page.items, isEmpty);
      expect(page.total, 0);
    });
  });

  group('KitsuUnitsRepository', () {
    late List<Uri> requested;

    KitsuUnitsRepository repo() {
      requested = [];
      final client = ApiClient(
        baseUrl: kKitsuBaseUrl,
        client: MockClient((request) async {
          requested.add(request.url);
          return http.Response(
            jsonEncode(_episodesJson),
            200,
            headers: {
              'content-type': 'application/vnd.api+json; charset=utf-8',
            },
          );
        }),
        minGap: Duration.zero,
        retryDelay: Duration.zero,
      );
      return KitsuUnitsRepository(client);
    }

    test('аниме: просит /anime/{id}/episodes с нужной страницей', () async {
      final item = _item(kKitsuAnimeIdOffset + 21);
      final page = await repo().getUnits(item, page: 2);

      expect(page.total, 1100);
      final url = requested.single;
      expect(url.path, endsWith('/anime/21/episodes'));
      expect(url.queryParameters['page[limit]'], '20');
      expect(url.queryParameters['page[offset]'], '40');
      expect(url.queryParameters['sort'], 'number');
    });

    test('манга: просит /manga/{id}/chapters', () async {
      final item = _item(kKitsuMangaIdOffset + 2, type: MediaType.manga);
      await repo().getUnits(item, page: 0);

      final url = requested.single;
      expect(url.path, endsWith('/manga/2/chapters'));
      // Первая страница уходит без offset
      expect(url.queryParameters.containsKey('page[offset]'), isFalse);
    });

    test('тайтл не из Kitsu: пустая страница и ни одного запроса', () async {
      final page = await repo().getUnits(_item(5), page: 0);

      expect(page.items, isEmpty);
      expect(requested, isEmpty);
    });
  });

  group('провайдеры списка серий', () {
    test('общее число берётся у сервера, если в карточке 0', () async {
      final container = _container(_FakeUnits(50));
      final item = _item(1);

      await container.read(unitsPageProvider((item: item, page: 0)).future);

      expect(container.read(unitsTotalProvider(item)), 50);
    });

    test('общее число из карточки не уменьшается', () async {
      final container = _container(_FakeUnits(5));
      final item = _item(1, units: 12);

      await container.read(unitsPageProvider((item: item, page: 0)).future);

      expect(container.read(unitsTotalProvider(item)), 12);
    });

    test('данные серии берутся из нужной страницы', () async {
      final container = _container(_FakeUnits(50));
      final item = _item(1);

      // Пока страница не пришла, данных нет
      expect(container.read(unitProvider((item: item, number: 25))), isNull);
      await container.read(unitsPageProvider((item: item, page: 1)).future);

      expect(
        container.read(unitProvider((item: item, number: 25)))?.title,
        'Эп 25',
      );
    });

    test('все главы собираются со всех страниц', () async {
      final repo = _FakeUnits(45);
      final container = _container(repo);
      final item = _item(1, type: MediaType.manga);

      final chapters = await container.read(mangaChaptersProvider(item).future);

      expect(chapters, hasLength(45));
      expect(repo.requests, 3);
    });

    test('слишком длинный тайтл не собирается целиком', () async {
      final repo = _FakeUnits(kMaxChaptersForVolumes + 1);
      final container = _container(repo);
      final item = _item(1, type: MediaType.manga);

      final chapters = await container.read(mangaChaptersProvider(item).future);

      expect(chapters, hasLength(kUnitsPageSize));
      expect(repo.requests, 1);
    });
  });

  group('groupByVolume', () {
    test('собирает главы по томам по возрастанию', () {
      final volumes = groupByVolume(const [
        MediaUnit(number: 11, volume: 2),
        MediaUnit(number: 1, volume: 1),
        MediaUnit(number: 2, volume: 1),
        MediaUnit(number: 99),
      ]);

      expect(volumes.keys, [1, 2]);
      expect(volumes[1]!.map((c) => c.number), [1, 2]);
      expect(volumes[2]!.map((c) => c.number), [11]);
    });

    test('без номеров томов словарь пуст', () {
      expect(groupByVolume(const [MediaUnit(number: 1)]), isEmpty);
    });
  });
}
