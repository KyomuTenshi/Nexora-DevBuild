import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/di/retry.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/core/theme/app_theme.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/repositories/kitsu_media_repository.dart';
import 'package:nexora/data/repositories/mock_media_repository.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/catalog_result_page.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/media_repository.dart';
import 'package:nexora/presentation/pages/catalog/catalog_grid.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ответ Kitsu с заданным числом записей (минимум полей, чтобы разобрались).
Map<String, dynamic> _kitsuPage(String type, int count) => {
  'data': [
    for (var i = 1; i <= count; i++)
      {
        'id': '$i',
        'type': type,
        'attributes': {
          'canonicalTitle': '$type $i',
          'averageRating': '80.0',
          'popularityRank': i,
          'episodeCount': 12,
          'chapterCount': 12,
          'status': 'finished',
          'startDate': '2020-01-01',
        },
      },
  ],
};

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/vnd.api+json; charset=utf-8'},
);

KitsuMediaRepository _kitsu(MockClientHandler handler) {
  final client = ApiClient(
    baseUrl: kKitsuBaseUrl,
    client: MockClient(handler),
    minGap: Duration.zero,
    retryDelay: Duration.zero,
  );
  return KitsuMediaRepository(client);
}

/// Мок с маленькой страницей: пять страниц по 4 записи на 15 тайтлов.
MockMediaRepository _mock({int pageSize = 4}) => MockMediaRepository(
  homeDelay: Duration.zero,
  searchDelay: Duration.zero,
  pageSize: pageSize,
);

/// Вторая и следующие страницы падают, пока не сказать [failPages] = false.
class _FlakyRepo extends MockMediaRepository {
  _FlakyRepo()
    : super(homeDelay: Duration.zero, searchDelay: Duration.zero, pageSize: 4);

  bool failPages = true;
  int pageCalls = 0;

  @override
  Future<CatalogResultPage> searchCatalogPage(
    CatalogQuery query, {
    int page = 0,
  }) async {
    pageCalls++;
    if (page > 0 && failPages) {
      throw const NetworkException('нет сети');
    }
    return super.searchCatalogPage(query, page: page);
  }
}

/// Вторая страница «зависает», пока не сработает [gate].
class _SlowRepo extends MockMediaRepository {
  _SlowRepo()
    : super(homeDelay: Duration.zero, searchDelay: Duration.zero, pageSize: 4);

  final gate = Completer<void>();

  @override
  Future<CatalogResultPage> searchCatalogPage(
    CatalogQuery query, {
    int page = 0,
  }) async {
    if (page > 0) await gate.future;
    return super.searchCatalogPage(query, page: page);
  }
}

ProviderContainer _container(MediaRepository repository) {
  final container = ProviderContainer(
    retry: noAutoRetry,
    overrides: [mediaRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  // Держим провайдер «под наблюдением», как это делает экран
  final subscription = container.listen(catalogFeedProvider, (_, _) {});
  addTearDown(subscription.close);
  return container;
}

CatalogFeed _feed(ProviderContainer container) =>
    container.read(catalogFeedProvider).requireValue;

void main() {
  group('KitsuMediaRepository: страницы', () {
    test('первая страница без offset, следующая с offset', () async {
      final requests = <Uri>[];
      final repo = _kitsu((request) async {
        requests.add(request.url);
        final isManga = request.url.path.endsWith('/manga');
        return _json(_kitsuPage(isManga ? 'manga' : 'anime', 20));
      });

      final first = await repo.searchCatalogPage(const CatalogQuery());
      expect(first.items, hasLength(40)); // 20 аниме + 20 манги
      expect(first.hasMore, isTrue);
      expect(
        requests.any((u) => u.queryParameters.containsKey('page[offset]')),
        isFalse,
      );

      requests.clear();
      await repo.searchCatalogPage(const CatalogQuery(), page: 2);
      expect(requests, hasLength(2));
      expect(
        requests.map((u) => u.queryParameters['page[offset]']),
        everyElement('40'), // страница 2 при 20 записях на странице
      );
    });

    test('неполная страница значит, что дальше ничего нет', () async {
      final repo = _kitsu((request) async {
        final isManga = request.url.path.endsWith('/manga');
        return _json(_kitsuPage(isManga ? 'manga' : 'anime', 5));
      });

      final page = await repo.searchCatalogPage(const CatalogQuery());

      expect(page.items, hasLength(10));
      expect(page.hasMore, isFalse);
    });

    test('searchCatalog по-прежнему отдаёт первую страницу списком', () async {
      final repo = _kitsu((request) async {
        final isManga = request.url.path.endsWith('/manga');
        return _json(_kitsuPage(isManga ? 'manga' : 'anime', 3));
      });

      final items = await repo.searchCatalog(const CatalogQuery());

      expect(items, hasLength(6));
    });
  });

  group('CatalogFeedNotifier', () {
    test('подгружает страницы до конца списка и там останавливается', () async {
      final container = _container(_mock());
      final notifier = container.read(catalogFeedProvider.notifier);

      await container.read(catalogFeedProvider.future);
      expect(_feed(container).items, hasLength(4));
      expect(_feed(container).hasMore, isTrue);

      await notifier.loadMore();
      expect(_feed(container).items, hasLength(8));
      await notifier.loadMore();
      expect(_feed(container).items, hasLength(12));
      await notifier.loadMore();
      expect(_feed(container).items, hasLength(15)); // всего 15 тайтлов
      expect(_feed(container).hasMore, isFalse);

      await notifier.loadMore(); // дальше ничего нет: без изменений
      expect(_feed(container).items, hasLength(15));
    });

    test('в списке нет повторов по id', () async {
      final container = _container(_mock());
      final notifier = container.read(catalogFeedProvider.notifier);

      await container.read(catalogFeedProvider.future);
      await notifier.loadMore();
      await notifier.loadMore();
      await notifier.loadMore();

      final ids = _feed(container).items.map((i) => i.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test(
      'ошибка подгрузки не стирает список; автоповтора нет, кнопка работает',
      () async {
        final repo = _FlakyRepo();
        final container = _container(repo);
        final notifier = container.read(catalogFeedProvider.notifier);
        await container.read(catalogFeedProvider.future);

        await notifier.loadMore();

        expect(_feed(container).items, hasLength(4)); // список на месте
        expect(_feed(container).moreError, isA<NetworkException>());
        expect(_feed(container).loadingMore, isFalse);

        // Прокрутка не должна бесконечно дёргать упавший сервер
        final callsAfterError = repo.pageCalls;
        await notifier.loadMore();
        expect(repo.pageCalls, callsAfterError);

        // «Повторить» после того, как сеть вернулась
        repo.failPages = false;
        await notifier.retryLoadMore();
        expect(_feed(container).items, hasLength(8));
        expect(_feed(container).moreError, isNull);
      },
    );

    test('ответ на старый запрос после смены фильтра выбрасывается', () async {
      final repo = _SlowRepo();
      final container = _container(repo);
      await container.read(catalogFeedProvider.future);

      // Вторая страница ушла и ждёт ответа
      final loading = container.read(catalogFeedProvider.notifier).loadMore();

      // Человек успел сменить запрос: список строится заново
      container
          .read(catalogQueryProvider.notifier)
          .setText('такого тайтла точно нет');
      await container.read(catalogFeedProvider.future);

      // Старая страница наконец пришла
      repo.gate.complete();
      await loading;

      // В новом списке не должно быть чужих записей
      expect(_feed(container).items, isEmpty);
    });

    test('пока список перезагружается, подгрузка не стартует', () async {
      final repo = _FlakyRepo()..failPages = false;
      final container = _container(repo);
      await container.read(catalogFeedProvider.future);
      final callsBefore = repo.pageCalls;

      // Сменили сортировку: чтение провайдера запускает перезагрузку
      container.read(catalogQueryProvider.notifier).setSort(CatalogSort.rating);
      expect(container.read(catalogFeedProvider).isLoading, isTrue);

      // Прокрутка в этот момент пытается подгрузить страницу: её быть не должно
      await container.read(catalogFeedProvider.notifier).loadMore();
      await container.read(catalogFeedProvider.future);

      expect(
        repo.pageCalls,
        callsBefore + 1,
      ); // только первая страница нового запроса
      expect(_feed(container).items, hasLength(4));
    });
  });

  group('PagedCatalogGrid', () {
    Future<void> pumpGrid(WidgetTester tester, MediaRepository repo) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          retry: noAutoRetry,
          overrides: [
            prefsProvider.overrideWithValue(prefs),
            mediaRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(AppColors.primary),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final feed = ref.watch(catalogFeedProvider).value;
                  return feed == null
                      ? const SizedBox()
                      : PagedCatalogGrid(feed: feed);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('«Показать ещё» подгружает следующую страницу', (tester) async {
      await pumpGrid(tester, _mock());

      expect(find.text('Показать ещё'), findsOneWidget);

      await tester.tap(find.text('Показать ещё'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(PagedCatalogGrid)),
      );
      expect(_feed(container).items, hasLength(8));
    });

    testWidgets('в конце списка вместо кнопки надпись «Это всё»', (
      tester,
    ) async {
      // Все 15 тайтлов в одной странице: подгружать больше нечего
      await pumpGrid(tester, _mock(pageSize: 50));

      await tester.scrollUntilVisible(find.text('Это всё'), 500);

      expect(find.text('Это всё'), findsOneWidget);
      expect(find.text('Показать ещё'), findsNothing);
    });
  });
}
