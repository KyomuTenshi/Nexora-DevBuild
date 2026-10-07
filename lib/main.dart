import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/di/providers.dart';
import 'core/di/retry.dart';
import 'data/local/hive_favorites_repository.dart';
import 'data/local/hive_library_repository.dart';
import 'data/local/hive_ratings_repository.dart';
import 'data/local/hive_response_cache.dart';
import 'data/repositories/in_memory_favorites_repository.dart';
import 'data/repositories/in_memory_library_repository.dart';
import 'data/repositories/in_memory_ratings_repository.dart';

Future<void> main() async {
  // Нужно, чтобы вызывать платформенный код до runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Настройки читаем один раз при старте: дальше доступ к ним синхронный
  final prefs = await SharedPreferences.getInstance();

  // Hive хранит данные в файлах в папке приложения
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  final libraryBox = await Hive.openBox<String>('library');
  final favoritesBox = await Hive.openBox<String>('favorites');
  final ratingsBox = await Hive.openBox<String>('ratings');
  final cacheBox = await Hive.openBox<String>('http_cache');

  // При самом первом запуске кладём стартовые демо-данные, дальше живут свои
  final library = HiveLibraryRepository(libraryBox);
  await library.seedIfFirstRun(InMemoryLibraryRepository().getAll());
  final favorites = HiveFavoritesRepository(favoritesBox);
  await favorites.seedIfFirstRun(InMemoryFavoritesRepository().getAll());
  final ratings = HiveRatingsRepository(ratingsBox);
  await ratings.seedIfFirstRun(InMemoryRatingsRepository().getAll());

  runApp(
    // ProviderScope хранит все Riverpod-провайдеры приложения
    ProviderScope(
      retry: noAutoRetry,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        libraryRepositoryProvider.overrideWithValue(library),
        favoritesRepositoryProvider.overrideWithValue(favorites),
        ratingsRepositoryProvider.overrideWithValue(ratings),
        responseCacheProvider.overrideWithValue(HiveResponseCache(cacheBox)),
      ],
      child: const NexoraApp(),
    ),
  );
}