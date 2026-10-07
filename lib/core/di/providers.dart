import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/core/di/cache_status.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/api/response_cache.dart';
import 'package:nexora/data/repositories/in_memory_favorites_repository.dart';
import 'package:nexora/data/repositories/in_memory_library_repository.dart';
import 'package:nexora/data/repositories/in_memory_ratings_repository.dart';
import 'package:nexora/data/repositories/kitsu_media_repository.dart';
import 'package:nexora/domain/repositories/favorites_repository.dart';
import 'package:nexora/domain/repositories/library_repository.dart';
import 'package:nexora/domain/repositories/media_repository.dart';
import 'package:nexora/domain/repositories/ratings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dependency Injection: единственное место, где выбирается реализация.
/// Остальной код просит интерфейс и не знает, настоящий он или тестовый.
///
/// По умолчанию здесь простые реализации в памяти (их использует каждый тест).
/// Настоящие хранилища на диске (Hive) подставляются в main() через overrides.

/// Постоянный кэш ответов API. По умолчанию его нет (в тестах), а в main()
/// подставляется Hive-реализация.
final responseCacheProvider = Provider<ResponseCache?>((ref) => null);

/// HTTP-клиент для Kitsu. Kitsu требует заголовок Accept: application/vnd.api+json.
final kitsuClientProvider = Provider<ApiClient>((ref) {
  // После закрытия провайдера поздние ответы не должны трогать состояние
  var alive = true;
  final client = ApiClient(
    baseUrl: kKitsuBaseUrl,
    headers: const {'Accept': 'application/vnd.api+json'},
    cache: ref.watch(responseCacheProvider),
    onStaleData: () {
      if (alive) ref.read(cacheStatusProvider.notifier).set(true);
    },
    onFreshData: () {
      if (alive) ref.read(cacheStatusProvider.notifier).set(false);
    },
  );
  ref.onDispose(() {
    alive = false;
    client.close();
  });
  return client;
});

/// Источник данных каталога. Сейчас это Kitsu.
/// Чтобы работать без сети, верните здесь `MockMediaRepository()`.
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return KitsuMediaRepository(ref.watch(kitsuClientProvider));
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return InMemoryLibraryRepository();
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return InMemoryFavoritesRepository();
});

final ratingsRepositoryProvider = Provider<RatingsRepository>((ref) {
  return InMemoryRatingsRepository();
});

/// SharedPreferences открывается один раз в main() и подставляется сюда
/// через overrides. Так доступ к настройкам синхронный и удобный для тестов.
final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider нужно переопределить в main()');
});