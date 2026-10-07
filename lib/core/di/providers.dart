import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/repositories/in_memory_library_repository.dart';
import 'package:nexora/data/repositories/kitsu_media_repository.dart';
import 'package:nexora/domain/repositories/library_repository.dart';
import 'package:nexora/domain/repositories/media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dependency Injection: единственное место, где выбирается реализация.
/// Остальной код просит интерфейс и не знает, настоящий он или тестовый.

/// HTTP-клиент для Kitsu. Kitsu требует заголовок Accept: application/vnd.api+json.
final kitsuClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: kKitsuBaseUrl,
    headers: const {'Accept': 'application/vnd.api+json'},
  );
  ref.onDispose(client.close);
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

/// SharedPreferences открывается один раз в main() и подставляется сюда
/// через overrides. Так доступ к настройкам синхронный и удобный для тестов.
final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider нужно переопределить в main()');
});