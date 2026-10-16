import 'package:nexora/data/cloud/push_quietly.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/repositories/cloud_sync_repository.dart';
import 'package:nexora/domain/repositories/library_repository.dart';

/// Библиотека: диск + облако (см. CloudBackedFavoritesRepository).
class CloudBackedLibraryRepository implements LibraryRepository {
  CloudBackedLibraryRepository({
    required this.local,
    required this.cloud,
    required this.currentUid,
  });

  final LibraryRepository local;
  final CloudSyncRepository cloud;
  final String? Function() currentUid;

  @override
  List<LibraryEntry> getAll() => local.getAll();

  @override
  Future<void> upsert(LibraryEntry entry) async {
    await local.upsert(entry);
    final uid = currentUid();
    if (uid != null) pushQuietly(() => cloud.saveLibraryEntry(uid, entry));
  }

  @override
  Future<void> remove(int itemId) async {
    await local.remove(itemId);
    final uid = currentUid();
    if (uid != null) pushQuietly(() => cloud.removeLibraryEntry(uid, itemId));
  }
}
