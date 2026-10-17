import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/data/repositories/cloud_backed_favorites_repository.dart';
import 'package:nexora/data/repositories/cloud_backed_library_repository.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/cloud_sync_repository.dart';
import 'package:nexora/domain/repositories/favorites_repository.dart';
import 'package:nexora/domain/repositories/library_repository.dart';

class MockCloud extends Mock implements CloudSyncRepository {}

class MockFavorites extends Mock implements FavoritesRepository {}

class MockLibrary extends Mock implements LibraryRepository {}

MediaItem _item(int id) => MediaItem(
  id: id,
  title: 'Тайтл $id',
  type: MediaType.anime,
  rating: 8,
  totalUnits: 12,
);

LibraryEntry _entry(int id) => LibraryEntry(
  item: _item(id),
  status: LibraryStatus.planned,
  progress: 0,
  updatedAt: DateTime(2026),
);

void main() {
  setUpAll(() {
    // mocktail нужен образец объекта, чтобы понимать any() для этих типов
    registerFallbackValue(_item(0));
    registerFallbackValue(_entry(0));
  });

  late MockCloud cloud;
  String? uid;

  setUp(() {
    cloud = MockCloud();
    uid = 'u1';
  });

  group('избранное', () {
    late MockFavorites local;
    late CloudBackedFavoritesRepository repo;

    setUp(() {
      local = MockFavorites();
      when(() => local.add(any())).thenAnswer((_) async {});
      when(() => local.remove(any())).thenAnswer((_) async {});
      when(() => cloud.saveFavorite(any(), any())).thenAnswer((_) async {});
      when(() => cloud.removeFavorite(any(), any())).thenAnswer((_) async {});
      repo = CloudBackedFavoritesRepository(
        local: local,
        cloud: cloud,
        currentUid: () => uid,
      );
    });

    test('чтение идёт с диска и не трогает облако', () {
      when(() => local.getAll()).thenReturn([_item(1)]);

      expect(repo.getAll().single.id, 1);

      verifyZeroInteractions(cloud);
    });

    test('вошедший: запись на диск и в облако', () async {
      await repo.add(_item(7));

      verify(() => local.add(any(that: isA<MediaItem>()))).called(1);
      verify(() => cloud.saveFavorite('u1', any())).called(1);
    });

    test('не вошедший: только диск', () async {
      uid = null;

      await repo.add(_item(7));
      await repo.remove(7);

      verify(() => local.add(any())).called(1);
      verify(() => local.remove(7)).called(1);
      verifyZeroInteractions(cloud);
    });

    test('удаление тоже уходит в облако', () async {
      await repo.remove(7);

      verify(() => local.remove(7)).called(1);
      verify(() => cloud.removeFavorite('u1', 7)).called(1);
    });

    test('сбой облака не ломает локальную запись', () async {
      when(() => cloud.saveFavorite(any(), any()))
          .thenAnswer((_) async => throw const NetworkException('нет сети'));

      await repo.add(_item(7)); // не должно бросить исключение
      await pumpEventQueue(); // даём фоновой отправке упасть

      verify(() => local.add(any())).called(1);
    });

    test('если диск упал, в облако ничего не отправляется', () async {
      when(() => local.add(any())).thenThrow(StateError('диск'));

      await expectLater(repo.add(_item(7)), throwsStateError);

      verifyZeroInteractions(cloud);
    });
  });

  group('библиотека', () {
    late MockLibrary local;
    late CloudBackedLibraryRepository repo;

    setUp(() {
      local = MockLibrary();
      when(() => local.upsert(any())).thenAnswer((_) async {});
      when(() => local.remove(any())).thenAnswer((_) async {});
      when(() => cloud.saveLibraryEntry(any(), any())).thenAnswer((_) async {});
      when(() => cloud.removeLibraryEntry(any(), any()))
          .thenAnswer((_) async {});
      repo = CloudBackedLibraryRepository(
        local: local,
        cloud: cloud,
        currentUid: () => uid,
      );
    });

    test('вошедший: запись на диск и в облако', () async {
      await repo.upsert(_entry(5));

      verify(() => local.upsert(any())).called(1);
      verify(() => cloud.saveLibraryEntry('u1', any())).called(1);
    });

    test('не вошедший: только диск', () async {
      uid = null;

      await repo.upsert(_entry(5));
      await repo.remove(5);

      verify(() => local.upsert(any())).called(1);
      verify(() => local.remove(5)).called(1);
      verifyZeroInteractions(cloud);
    });

    test('удаление уходит в облако', () async {
      await repo.remove(5);

      verify(() => local.remove(5)).called(1);
      verify(() => cloud.removeLibraryEntry('u1', 5)).called(1);
    });
  });
}
