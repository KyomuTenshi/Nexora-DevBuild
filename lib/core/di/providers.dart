import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/repositories/in_memory_library_repository.dart';
import 'package:nexora/data/repositories/mock_media_repository.dart';
import 'package:nexora/domain/repositories/library_repository.dart';
import 'package:nexora/domain/repositories/media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dependency Injection: единственное место, где выбирается реализация.
/// Остальной код просит интерфейс и не знает, тестовый он или настоящий.
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MockMediaRepository();
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return InMemoryLibraryRepository();
});

/// SharedPreferences открывается один раз в main() и подставляется сюда
/// через overrides. Так доступ к настройкам синхронный и удобный для тестов.
final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider нужно переопределить в main()');
});
