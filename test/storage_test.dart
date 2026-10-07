import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/api/response_cache.dart';
import 'package:nexora/data/local/hive_favorites_repository.dart';
import 'package:nexora/data/local/hive_library_repository.dart';
import 'package:nexora/data/local/hive_ratings_repository.dart';
import 'package:nexora/data/local/hive_response_cache.dart';
import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/data/repositories/in_memory_favorites_repository.dart';
import 'package:nexora/data/repositories/in_memory_library_repository.dart';
import 'package:nexora/data/repositories/in_memory_ratings_repository.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/errors/app_exception.dart';

/// Кэш в памяти: для проверки логики клиента не нужен диск.
class _MemoryCache implements ResponseCache {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String body) async {
    data[key] = body;
  }
}

void main() {
  group('Hive: данные переживают перезапуск', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('nexora_hive_');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('библиотека: прогресс сохраняется, удалённое не возвращается',
            () async {
          var box = await Hive.openBox<String>('library');
          var repo = HiveLibraryRepository(box);
          await repo.seedIfFirstRun(InMemoryLibraryRepository().getAll());
          await repo.upsert(LibraryEntry(
            item: MockData.dandadan,
            status: LibraryStatus.inProgress,
            progress: 7,
            updatedAt: DateTime.now(),
          ));
          await repo.remove(MockData.vagabond.id);
          await box.close();

          // «Перезапуск»: открываем то же хранилище заново
          box = await Hive.openBox<String>('library');
          repo = HiveLibraryRepository(box);
          await repo.seedIfFirstRun(InMemoryLibraryRepository().getAll());
          final all = {for (final e in repo.getAll()) e.item.id: e};

          expect(all[MockData.dandadan.id]!.progress, 7);
          expect(all[MockData.dandadan.id]!.status, LibraryStatus.inProgress);
          expect(all[MockData.onePiece.id]!.item.title, 'One Piece');
          // Демо-данные второй раз не добавляются, удалённое не воскресает
          expect(all.containsKey(MockData.vagabond.id), isFalse);
        });

    test('избранное: порядок добавления сохраняется', () async {
      var box = await Hive.openBox<String>('favorites');
      var repo = HiveFavoritesRepository(box);
      await repo.seedIfFirstRun(InMemoryFavoritesRepository().getAll());
      await repo.add(MockData.frieren);
      await repo.remove(MockData.jujutsu.id);
      await box.close();

      box = await Hive.openBox<String>('favorites');
      repo = HiveFavoritesRepository(box);

      expect(
        repo.getAll().map((i) => i.title),
        ['One Piece', 'Vinland Saga', 'Frieren'],
      );
    });

    test('оценки: сохраняются и снимаются', () async {
      var box = await Hive.openBox<String>('ratings');
      var repo = HiveRatingsRepository(box);
      await repo.seedIfFirstRun(InMemoryRatingsRepository().getAll());
      await repo.set(MockData.frieren.id, 5);
      await repo.remove(MockData.jujutsu.id);
      await box.close();

      box = await Hive.openBox<String>('ratings');
      repo = HiveRatingsRepository(box);

      expect(repo.getAll(), {MockData.frieren.id: 5});
    });

    test('кэш ответов: читается по длинному адресу и не растёт бесконечно',
            () async {
          final box = await Hive.openBox<String>('http_cache');
          final cache = HiveResponseCache(box, maxEntries: 3);
          final longUrl = 'https://example.test/anime?${'a=b&' * 100}';

          await cache.write(longUrl, '{"ok":true}');
          expect(cache.read(longUrl), '{"ok":true}');
          expect(cache.read('https://example.test/other'), isNull);

          for (var i = 0; i < 5; i++) {
            await cache.write('https://example.test/page/$i', '{"n":$i}');
          }
          expect(box.length, lessThanOrEqualTo(3));
        });
  });

  group('ApiClient: offline-first', () {
    ApiClient makeClient(
        MockClientHandler handler,
        ResponseCache? cache, {
          void Function()? onStale,
          void Function()? onFresh,
        }) {
      return ApiClient(
        baseUrl: 'https://example.test',
        client: MockClient(handler),
        cache: cache,
        minGap: Duration.zero,
        retryDelay: Duration.zero,
        onStaleData: onStale,
        onFreshData: onFresh,
      );
    }

    test('без сети отдаёт сохранённые данные и сообщает об этом', () async {
      final cache = _MemoryCache();
      var online = true;
      var stale = 0;
      var fresh = 0;
      final client = makeClient(
            (request) async {
          if (!online) throw http.ClientException('offline');
          return http.Response(jsonEncode({'data': [1]}), 200);
        },
        cache,
        onStale: () => stale++,
        onFresh: () => fresh++,
      );

      final first = await client.getJson('/anime');
      expect(first['data'], [1]);
      expect(fresh, 1);
      expect(stale, 0);

      // Сети больше нет, а кэш в памяти сброшен (как после перезапуска)
      online = false;
      client.clearCache();
      final second = await client.getJson('/anime');

      expect(second['data'], [1]);
      expect(stale, 1);
    });

    test('без сети и без сохранённых данных ошибка остаётся', () async {
      final client = makeClient(
            (request) async => throw http.ClientException('offline'),
        _MemoryCache(),
      );

      expect(client.getJson('/anime'), throwsA(isA<NetworkException>()));
    });

    test('ошибка сервера 500 тоже заменяется сохранёнными данными', () async {
      final cache = _MemoryCache();
      var status = 200;
      final client = makeClient(
            (request) async => http.Response(jsonEncode({'data': []}), status),
        cache,
      );

      await client.getJson('/manga');
      status = 500;
      client.clearCache();
      final json = await client.getJson('/manga');

      expect(json['data'], isEmpty);
    });

    test('неверный формат ответа не заменяется сохранёнными данными',
            () async {
          final cache = _MemoryCache();
          var broken = false;
          final client = makeClient(
                (request) async => http.Response(
              broken ? '<html>' : jsonEncode({'data': []}),
              200,
            ),
            cache,
          );

          await client.getJson('/anime');
          broken = true;
          client.clearCache();

          expect(client.getJson('/anime'), throwsA(isA<ParseException>()));
        });
  });
}