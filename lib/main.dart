import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/di/auth_providers.dart';
import 'core/di/cloud_providers.dart';
import 'core/di/providers.dart';
import 'core/di/push_providers.dart';
import 'core/di/retry.dart';
import 'data/cloud/firestore_cloud_sync_repository.dart';
import 'data/local/hive_favorites_repository.dart';
import 'data/local/hive_library_repository.dart';
import 'data/local/hive_ratings_repository.dart';
import 'data/local/hive_response_cache.dart';
import 'data/push/firebase_push_background.dart';
import 'data/push/firebase_push_repository.dart';
import 'data/repositories/cloud_backed_favorites_repository.dart';
import 'data/repositories/cloud_backed_library_repository.dart';
import 'data/repositories/firebase_auth_repository.dart';
import 'data/repositories/in_memory_favorites_repository.dart';
import 'data/repositories/in_memory_library_repository.dart';
import 'data/repositories/in_memory_ratings_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Нужно, чтобы вызывать платформенный код до runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Подключаемся к проекту Firebase (настройки создал flutterfire configure)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Обработчик push, когда приложение закрыто или в фоне
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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

  // Авторизация, облако и push. Запись в облако идёт только при входе в аккаунт.
  final auth = FirebaseAuthRepository(FirebaseAuth.instance);
  final firestore = FirebaseFirestore.instance;
  final cloud = FirestoreCloudSyncRepository(firestore);
  final push = FirebasePushRepository(FirebaseMessaging.instance, firestore);
  String? currentUid() => auth.currentUser?.uid;

  runApp(
    // ProviderScope хранит все Riverpod-провайдеры приложения
    ProviderScope(
      retry: noAutoRetry,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        // Приложение работает с «диск + облако», синхронизация — с чистым диском
        libraryRepositoryProvider.overrideWithValue(
          CloudBackedLibraryRepository(
            local: library,
            cloud: cloud,
            currentUid: currentUid,
          ),
        ),
        favoritesRepositoryProvider.overrideWithValue(
          CloudBackedFavoritesRepository(
            local: favorites,
            cloud: cloud,
            currentUid: currentUid,
          ),
        ),
        localLibraryRepositoryProvider.overrideWithValue(library),
        localFavoritesRepositoryProvider.overrideWithValue(favorites),
        ratingsRepositoryProvider.overrideWithValue(ratings),
        responseCacheProvider.overrideWithValue(HiveResponseCache(cacheBox)),
        authRepositoryProvider.overrideWithValue(auth),
        cloudSyncRepositoryProvider.overrideWithValue(cloud),
        pushRepositoryProvider.overrideWithValue(push),
      ],
      child: const NexoraApp(),
    ),
  );
}