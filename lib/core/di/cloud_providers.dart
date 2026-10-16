import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/data/cloud/in_memory_cloud_sync_repository.dart';
import 'package:nexora/domain/repositories/cloud_sync_repository.dart';
import 'package:nexora/domain/repositories/favorites_repository.dart';
import 'package:nexora/domain/repositories/library_repository.dart';

/// Облако. По умолчанию в памяти (тесты), в main() подставляется Firestore.
final cloudSyncRepositoryProvider = Provider<CloudSyncRepository>((ref) {
  return InMemoryCloudSyncRepository();
});

/// Хранилища «только диск», без отправки в облако. Нужны самой синхронизации,
/// чтобы подтянутые из облака данные не отправлялись туда же обратно.
/// По умолчанию совпадают с обычными, в main() подставляются чистые Hive-версии.
final localLibraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return ref.watch(libraryRepositoryProvider);
});

final localFavoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return ref.watch(favoritesRepositoryProvider);
});