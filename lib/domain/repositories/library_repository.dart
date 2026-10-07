import '../entities/library_entry.dart';

/// Контракт хранилища библиотеки пользователя.
/// getAll синхронный: данные уже лежат в памяти (на этапе 6 их загрузит Hive).
abstract class LibraryRepository {
  List<LibraryEntry> getAll();
  Future<void> upsert(LibraryEntry entry);
  Future<void> remove(int itemId);
}
