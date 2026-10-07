import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/dto/kitsu_dto.dart';
import 'package:nexora/data/repositories/kitsu_media_repository.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';

/// Ответ в том же формате, что отдаёт Kitsu (JSON:API, поля сокращены).
const _animeJson = {
  'data': [
    {
      'id': '12',
      'type': 'anime',
      'attributes': {
        'canonicalTitle': 'One Piece',
        'titles': {'en': 'One Piece', 'en_jp': 'One Piece'},
        'averageRating': '82.5',
        'userCount': 400000,
        'popularityRank': 3,
        'episodeCount': null,
        'status': 'current',
        'startDate': '1999-10-20',
        'synopsis': 'Pirates.\r\n(Source: Crunchyroll)',
        'posterImage': {'large': 'https://cdn.example/op.jpg'},
      },
      'relationships': {
        'categories': {
          'data': [
            {'type': 'categories', 'id': '1'},
            {'type': 'categories', 'id': '2'},
          ],
        },
      },
    },
    // Битая запись без названия не должна ломать весь список
    {'id': '999', 'type': 'anime', 'attributes': <String, dynamic>{}},
  ],
  'included': [
    {
      'id': '1',
      'type': 'categories',
      'attributes': {'title': 'Action'},
    },
    {
      'id': '2',
      'type': 'categories',
      'attributes': {'title': 'Science Fiction'},
    },
  ],
};

const _mangaJson = {
  'data': [
    {
      'id': '2',
      'type': 'manga',
      'attributes': {
        'canonicalTitle': 'Berserk',
        'averageRating': '90.0',
        'popularityRank': 1,
        'chapterCount': null,
        'status': 'current',
        'startDate': '1989-08-25',
      },
    },
  ],
};

KitsuMediaRepository _repo(MockClientHandler handler) {
  final client = ApiClient(
    baseUrl: kKitsuBaseUrl,
    client: MockClient(handler),
    minGap: Duration.zero,
    retryDelay: Duration.zero,
  );
  return KitsuMediaRepository(client);
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/vnd.api+json; charset=utf-8'},
);

void main() {
  group('KitsuMediaDto', () {
    test('переводит JSON:API в MediaItem', () {
      final item =
      parseKitsuList(_animeJson).single.toDomain(MediaType.anime);

      expect(item.id, kKitsuAnimeIdOffset + 12);
      expect(item.title, 'One Piece');
      expect(item.rating, closeTo(8.25, 0.001));
      expect(item.totalUnits, 0); // у идущего аниме число серий неизвестно
      expect(item.status, AiringStatus.airing);
      expect(item.year, 1999);
      expect(item.season, 'Осень');
      expect(item.genres, ['Action', 'Sci-Fi']);
      expect(item.synopsis, 'Pirates.'); // источник в конце убран
      expect(item.imageUrl, 'https://cdn.example/op.jpg');
    });

    test('у манги id сдвинут отдельно, сезона нет', () {
      final item = parseKitsuList(_mangaJson).single.toDomain(MediaType.manga);

      expect(item.id, kKitsuMangaIdOffset + 2);
      expect(item.year, 1989);
      expect(item.season, isNull);
      expect(item.type, MediaType.manga);
    });
  });

  group('KitsuMediaRepository', () {
    test('каталог склеивает аниме и мангу, передаёт фильтры и сортирует',
            () async {
          final requests = <Uri>[];
          final repo = _repo((request) async {
            requests.add(request.url);
            return _json(
                request.url.path.endsWith('/manga') ? _mangaJson : _animeJson);
          });

          final items = await repo.searchCatalog(
            const CatalogQuery(genre: 'Action', sort: CatalogSort.popularity),
          );

          expect(requests, hasLength(2));
          final anime = requests.firstWhere((u) => u.path.endsWith('/anime'));
          expect(anime.queryParameters['filter[categories]'], 'action');
          expect(anime.queryParameters['sort'], 'popularityRank');
          expect(anime.queryParameters['include'], 'categories');
          // Берсерк (popularity 1) идёт раньше One Piece (popularity 3)
          expect(items.map((i) => i.title), ['Berserk', 'One Piece']);
        });

    test('если манга отвечает ошибкой сервера, остаётся аниме', () async {
      final repo = _repo((request) async {
        return request.url.path.endsWith('/manga')
            ? _json({}, 500)
            : _json(_animeJson);
      });

      final items = await repo.searchCatalog(const CatalogQuery());

      expect(items.map((i) => i.title), ['One Piece']);
    });

    test('сервер не принял фильтр года: запрос повторяется без него',
            () async {
          final animeRequests = <Uri>[];
          final repo = _repo((request) async {
            if (request.url.path.endsWith('/manga')) return _json(_mangaJson);
            animeRequests.add(request.url);
            return request.url.queryParameters.containsKey('filter[year]')
                ? _json({}, 400)
                : _json(_animeJson);
          });

          final items = await repo.searchCatalog(const CatalogQuery(year: 1999));

          expect(animeRequests, hasLength(2));
          // Год всё равно проверяется у нас: One Piece 1999 проходит
          expect(items.map((i) => i.title), contains('One Piece'));
        });

    test('одинаковые запросы берутся из кэша', () async {
      var calls = 0;
      final repo = _repo((request) async {
        calls++;
        return _json(_animeJson);
      });

      await repo.getHomeFeed();
      final first = calls;
      await repo.getHomeFeed();

      expect(calls, first);
    });

    test('HTTP 500 даёт ServerException с кодом', () async {
      final repo = _repo((request) async => _json({}, 500));

      expect(
        repo.getHomeFeed(),
        throwsA(isA<ServerException>().having((e) => e.statusCode, 'code', 500)),
      );
    });

    test('сбой соединения даёт NetworkException', () async {
      final repo = _repo((request) async {
        throw http.ClientException('no route to host');
      });

      expect(repo.getHomeFeed(), throwsA(isA<NetworkException>()));
    });

    test('неверный JSON даёт ParseException', () async {
      final repo = _repo((request) async => http.Response('<html>', 200));

      expect(repo.getHomeFeed(), throwsA(isA<ParseException>()));
    });
  });
}