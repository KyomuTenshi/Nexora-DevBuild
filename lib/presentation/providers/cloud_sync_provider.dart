import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/core/di/cloud_providers.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/data/cloud/push_quietly.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';

enum SyncStatus { idle, syncing, done, error }

/// Синхронизация диска и облака. Запускается сама при входе в аккаунт
/// и при старте приложения, если пользователь уже вошёл.
class CloudSyncNotifier extends Notifier<SyncStatus> {
  static const _lastUidKey = 'sync_uid';

  bool _running = false;
  String? _startedFor;

  @override
  SyncStatus build() {
    ref.listen(authStateProvider, (_, next) {
      final user = next.value;
      if (user == null) {
        _startedFor = null;
        state = SyncStatus.idle;
      } else if (user.uid != _startedFor) {
        unawaited(sync());
      }
    });

    // Пользователь уже вошёл при запуске приложения
    if (ref.read(authRepositoryProvider).currentUser != null) {
      Future.microtask(sync);
    }
    return SyncStatus.idle;
  }

  /// Слияние диска и облака. Можно вызвать вручную («Повторить»).
  Future<void> sync() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null || _running) return;

    _running = true;
    _startedFor = user.uid;
    state = SyncStatus.syncing;

    try {
      final uid = user.uid;
      final cloud = ref.read(cloudSyncRepositoryProvider);
      final localFavorites = ref.read(localFavoritesRepositoryProvider);
      final localLibrary = ref.read(localLibraryRepositoryProvider);
      final prefs = ref.read(prefsProvider);

      // Другой аккаунт на этом устройстве: чужие данные не смешиваем
      final lastUid = prefs.getString(_lastUidKey);
      if (lastUid != null && lastUid != uid) {
        for (final item in localFavorites.getAll()) {
          await localFavorites.remove(item.id);
        }
        for (final entry in localLibrary.getAll()) {
          await localLibrary.remove(entry.item.id);
        }
      }

      final cloudFavorites = await cloud.loadFavorites(uid);
      final cloudLibrary = await cloud.loadLibrary(uid);

      // Избранное: объединяем два списка
      final localFavoriteIds = {for (final i in localFavorites.getAll()) i.id};
      for (final item in cloudFavorites) {
        if (!localFavoriteIds.contains(item.id)) {
          await localFavorites.add(item);
        }
      }
      final cloudFavoriteIds = {for (final i in cloudFavorites) i.id};
      for (final item in localFavorites.getAll()) {
        if (!cloudFavoriteIds.contains(item.id)) {
          pushQuietly(() => cloud.saveFavorite(uid, item));
        }
      }

      // Библиотека: при конфликте побеждает запись, обновлённая позже
      final cloudById = {for (final e in cloudLibrary) e.item.id: e};
      final localById = {for (final e in localLibrary.getAll()) e.item.id: e};
      for (final remote in cloudById.values) {
        final local = localById[remote.item.id];
        if (local == null || remote.updatedAt.isAfter(local.updatedAt)) {
          await localLibrary.upsert(remote);
        }
      }
      for (final local in localById.values) {
        final remote = cloudById[local.item.id];
        if (remote == null || local.updatedAt.isAfter(remote.updatedAt)) {
          pushQuietly(() => cloud.saveLibraryEntry(uid, local));
        }
      }

      await prefs.setString(_lastUidKey, uid);

      // Экраны перечитывают списки с диска и показывают результат слияния
      ref.invalidate(favoritesProvider);
      ref.invalidate(libraryProvider);
      state = SyncStatus.done;
    } catch (e) {
      debugPrint('Синхронизация не удалась: $e');
      state = SyncStatus.error;
    } finally {
      _running = false;
    }
  }
}

final cloudSyncProvider = NotifierProvider<CloudSyncNotifier, SyncStatus>(
  CloudSyncNotifier.new,
);