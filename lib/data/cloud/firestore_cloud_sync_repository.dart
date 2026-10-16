import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexora/data/local/stored_json.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/cloud_sync_repository.dart';

/// Облако на Firestore. Структура:
///   users/{uid}/favorites/{itemId}  ->  {addedAt, item: {...}}
///   users/{uid}/library/{itemId}    ->  {item, status, progress, updatedAt}
/// Формат тайтла тот же, что и на диске (stored_json.dart).
class FirestoreCloudSyncRepository implements CloudSyncRepository {
  FirestoreCloudSyncRepository(this._db);

  final FirebaseFirestore _db;

  /// Без сети Firestore может ждать бесконечно, поэтому чтение ограничено.
  static const _readTimeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  CollectionReference<Map<String, dynamic>> _library(String uid) =>
      _db.collection('users').doc(uid).collection('library');

  @override
  Future<List<MediaItem>> loadFavorites(String uid) async {
    final snapshot = await _read(_favorites(uid));
    final result = <MediaItem>[];
    for (final doc in snapshot.docs) {
      try {
        final item = Map<String, dynamic>.from(doc.data()['item'] as Map);
        result.add(mediaItemFromJson(item));
      } catch (_) {
        // Повреждённую запись пропускаем
      }
    }
    return result;
  }

  @override
  Future<void> saveFavorite(String uid, MediaItem item) {
    return _favorites(uid).doc('${item.id}').set({
      'addedAt': DateTime.now().millisecondsSinceEpoch,
      'item': mediaItemToJson(item),
    });
  }

  @override
  Future<void> removeFavorite(String uid, int itemId) =>
      _favorites(uid).doc('$itemId').delete();

  @override
  Future<List<LibraryEntry>> loadLibrary(String uid) async {
    final snapshot = await _read(_library(uid));
    final result = <LibraryEntry>[];
    for (final doc in snapshot.docs) {
      try {
        result.add(libraryEntryFromJson(Map<String, dynamic>.from(doc.data())));
      } catch (_) {
        // Повреждённую запись пропускаем
      }
    }
    return result;
  }

  @override
  Future<void> saveLibraryEntry(String uid, LibraryEntry entry) {
    return _library(uid).doc('${entry.item.id}').set(libraryEntryToJson(entry));
  }

  @override
  Future<void> removeLibraryEntry(String uid, int itemId) =>
      _library(uid).doc('$itemId').delete();

  Future<QuerySnapshot<Map<String, dynamic>>> _read(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    try {
      return await collection.get().timeout(_readTimeout);
    } on TimeoutException {
      throw const NetworkException('Firestore: нет ответа');
    } on FirebaseException catch (e) {
      throw NetworkException('Firestore: ${e.code}');
    }
  }
}
