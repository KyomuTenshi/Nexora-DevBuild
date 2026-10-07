import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexora/data/api/jikan_client.dart';
import 'package:nexora/data/dto/jikan_dto.dart';
import 'package:nexora/data/repositories/jikan_media_repository.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';

/// Ответ в том же формате, что отдаёт Jikan (поля сокращены).
const _animeJson = {
  'data': [
    {
      'mal_id': 21,
      'title': 'One Piece',
      'title_english': 'One Piece',
      'images': {
        'jpg': {'large_image_url': 'https://cdn.example/op.jpg'},
      },
      'episodes': null,
      'status': 'Currently Airing',
      'score': 8.73,
      'scored_by': 1200000,
      'popularity': 15,
      'synopsis': 'Pirates.\n\n[Written by MAL Rewrite]',
      'year': 1999,
      'season': 'fall',
      'studios': [
        {'mal_id': 18, 'name': 'Toei Animation'},
      ],
      'genres': [
        {'mal_id': 1, 'name': 'Action'},
      ],
      'themes': [
        {'mal_id': 21, 'name': 'Historical'},
      ],
      'demographics': [
        {'mal_id': 27, 'name': 'Shounen'},
      ],
    },
    // Битая запись без названия не должна ломать весь список
    {'mal_id': 999},
  ],
};

const _mangaJson = {
  'data': [
    {
      'mal_id': 2,
      'title': 'Berserk',
      'chapters': null,
      'status': 'Publishing',
      'score': 9.47,
      'popularity': 3,
      'published': {
        'prop': {
          'from': {'year': 1989},
        },
      },
    },
  ],
};

JikanMediaRepository _repo(
    MockClientHandler handler, {
      int maxRetries = 1,
    }) {
  final client = JikanClient(
    client: MockClient(handler),
    minGap: Duration.zero,
    retryDelay: Duration.zero,
    maxRetries: maxRetries,
  );
  return JikanMediaRepository(client);
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('JikanMediaDto', () {
    test('переводит JSON в MediaItem', () {
      final dto = parseMediaList(_animeJson).single;
      final item = dto.toDomain(MediaType.anime);

      expect(item.id, 21);
      expect(item.title, 'One Piece');
      expect(item.rating, 8.73);
      expect(item.totalUnits, 0); // у идущего аниме число серий неизвестно
      expect(item.status, AiringStatus.airing);
      expect(item.season, 'Осень');
      expect(item.studio, 'Toei Animation');
      expect(item.genres, ['Action', 'Historical', 'Shounen']);
      expect(item.synopsis, 'Pirates.'); // служебная пометка убрана
      expect(item.imageUrl, 'https://cdn.example/op.jpg');
    });

    test('у манги id сдвинут, год берётся из published', () {
      final item = parseMediaList(_mangaJson).single.toDomain(MediaType.manga);

      expect(item.id, 10000002);
      expect(item.year, 1989);
      expect(item.type, MediaType.manga);
    });
  });

  group('JikanMediaRepository', () {
    test('каталог склеивает аниме и мангу, передаёт фильтры и сортирует',
            () async {
          final requests = <Uri>[];
          final repo = _repo((request) async {
            requests.add(request.url);
            return _json(request.url.path.endsWith('/manga')
                ? _mangaJson
                : _animeJson);
          });

          final items = await repo.searchCatalog(
            const CatalogQuery(genre: 'Action', sort: CatalogSort.popularity),
          );

          expect(requests, hasLength(2));
          final anime = requests.firstWhere((u) => u.path.endsWith('/anime'));
          expect(anime.queryParameters['genres'], '1');
          expect(anime.queryParameters['sfw'], 'true');
          expect(anime.queryParameters['order_by'], 'popularity');
          // Берсерк (popularity 3) идёт раньше One Piece (popularity 15)
          expect(items.map((i) => i.title), ['Berserk', 'One Piece']);
        });

    test('одинаковые запросы берутся из кэша', () async {
      var calls = 0;
      final repo = _repo((request) async {
        calls++;
        return _json(_animeJson);
      });

      await repo.searchCatalog(const CatalogQuery(studio: 'Toei Animation'));
      await repo.searchCatalog(const CatalogQuery(studio: 'Toei Animation'));

      expect(calls, 1);
    });

    test('HTTP 429 один раз повторяется и потом проходит', () async {
      var calls = 0;
      final repo = _repo((request) async {
        calls++;
        return calls == 1 ? _json({}, 429) : _json(_animeJson);
      });

      final items = await repo.searchCatalog(
        const CatalogQuery(studio: 'Toei Animation'),
      );

      expect(items, isNotEmpty);
      expect(calls, 2);
    });

    test('постоянный 429 даёт RateLimitException', () async {
      final repo = _repo((request) async => _json({}, 429));

      expect(
        repo.searchCatalog(const CatalogQuery(studio: 'Toei Animation')),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('HTTP 500 даёт ServerException с кодом', () async {
      final repo = _repo((request) async => _json({}, 500));

      expect(
        repo.searchCatalog(const CatalogQuery(studio: 'Toei Animation')),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'code', 500)),
      );
    });

    test('сбой соединения даёт NetworkException', () async {
      final repo = _repo((request) async {
        throw http.ClientException('no route to host');
      });

      expect(
        repo.searchCatalog(const CatalogQuery(studio: 'Toei Animation')),
        throwsA(isA<NetworkException>()),
      );
    });

    test('неверный JSON даёт ParseException', () async {
      final repo = _repo((request) async => http.Response('<html>', 200));

      expect(
        repo.searchCatalog(const CatalogQuery(studio: 'Toei Animation')),
        throwsA(isA<ParseException>()),
      );
    });

    test('ошибка не попадает в кэш: повтор запроса снова идёт в сеть',
            () async {
          var calls = 0;
          final repo = _repo((request) async {
            calls++;
            return calls == 1 ? _json({}, 500) : _json(_animeJson);
          });
          const query = CatalogQuery(studio: 'Toei Animation');

          await expectLater(
            repo.searchCatalog(query),
            throwsA(isA<ServerException>()),
          );
          final items = await repo.searchCatalog(query);

          expect(items, isNotEmpty);
        });
  });
}