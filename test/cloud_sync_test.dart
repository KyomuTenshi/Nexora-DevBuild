import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/core/di/cloud_providers.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/data/cloud/in_memory_cloud_sync_repository.dart';
import 'package:nexora/data/repositories/in_memory_auth_repository.dart';
import 'package:nexora/data/repositories/in_memory_favorites_repository.dart';
import 'package:nexora/data/repositories/in_memory_library_repository.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/cloud_sync_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

MediaItem _item(int id, String title) => MediaItem(
  id: id,
  title: title,
  type: MediaType.anime,
  rating: 8,
  totalUnits: 12,
);

Future<void> _waitForDone(ProviderContainer container) async {
  for (var i = 0; i < 100; i++) {
    final status = container.read(cloudSyncProvider);
    if (status == SyncStatus.done || status == SyncStatus.error) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  test('вход объединяет локальное избранное с облачным', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final auth = InMemoryAuthRepository();
    final cloud = InMemoryCloudSyncRepository();
    final favorites = InMemoryFavoritesRepository();
    final library = InMemoryLibraryRepository();

    // В облаке у пользователя уже есть тайтл, на устройстве другой
    await cloud.saveFavorite('a@b.com', _item(9001, 'Из облака'));
    await favorites.add(_item(9002, 'С устройства'));

    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        cloudSyncRepositoryProvider.overrideWithValue(cloud),
        favoritesRepositoryProvider.overrideWithValue(favorites),
        libraryRepositoryProvider.overrideWithValue(library),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(auth.dispose);

    // Включаем синхронизацию, затем входим в аккаунт
    container.listen(cloudSyncProvider, (_, _) {});
    expect(container.read(cloudSyncProvider), SyncStatus.idle);
    await auth.register(email: 'a@b.com', password: 'secret1');
    await _waitForDone(container);

    expect(container.read(cloudSyncProvider), SyncStatus.done);
    final localIds = favorites.getAll().map((i) => i.id);
    expect(localIds, containsAll([9001, 9002]));
    final cloudIds = cloud.favoritesOf('a@b.com').map((i) => i.id);
    expect(cloudIds, containsAll([9001, 9002]));
  });

  test('выход сбрасывает статус синхронизации', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = InMemoryAuthRepository();

    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(auth.dispose);

    container.listen(cloudSyncProvider, (_, _) {});
    await auth.register(email: 'a@b.com', password: 'secret1');
    await _waitForDone(container);
    expect(container.read(cloudSyncProvider), SyncStatus.done);

    await auth.signOut();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(cloudSyncProvider), SyncStatus.idle);
  });

  test('после регистрации имя профиля берётся из аккаунта', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = InMemoryAuthRepository();

    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        cloudSyncRepositoryProvider.overrideWithValue(
          InMemoryCloudSyncRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(auth.dispose);

    container.listen(cloudSyncProvider, (_, _) {});
    expect(container.read(profileProvider).name, isEmpty);
    await auth.register(email: 'anna@b.com', password: 'secret1');
    await _waitForDone(container);

    final profile = container.read(profileProvider);
    expect(profile.name, 'anna');
    expect(profile.avatarText, 'AN');
    expect(profile.points, 0);
  });

  test('другой аккаунт на устройстве начинает с чистого профиля', () async {
    final old = ProfileState.initial().copyWith(
      name: 'Старый',
      avatarText: 'СТ',
      points: 500,
      xp: 500,
    );
    SharedPreferences.setMockInitialValues({
      'sync_uid': 'old@b.com',
      'profile_v1': jsonEncode(old.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = InMemoryAuthRepository();

    final container = ProviderContainer(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        cloudSyncRepositoryProvider.overrideWithValue(
          InMemoryCloudSyncRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(auth.dispose);

    container.listen(cloudSyncProvider, (_, _) {});
    expect(container.read(profileProvider).points, 500);
    await auth.register(email: 'new@b.com', password: 'secret1');
    await _waitForDone(container);

    final profile = container.read(profileProvider);
    expect(profile.name, 'new');
    expect(profile.points, 0);
    expect(profile.xp, 0);
  });
}
