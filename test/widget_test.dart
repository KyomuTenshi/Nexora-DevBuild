import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/app.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/di/retry.dart';
import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/data/repositories/mock_media_repository.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/domain/entities/home_feed.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/media_repository.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Репозиторий, который всегда падает: проверяем экран ошибки.
class FailingMediaRepository implements MediaRepository {
  @override
  Future<HomeFeed> getHomeFeed() async =>
      throw const NetworkException('Нет подключения к интернету');

  @override
  Future<List<MediaItem>> searchCatalog(CatalogQuery query) async =>
      throw const NetworkException('Нет подключения к интернету');

  @override
  Future<String?> findCoverUrl(MediaItem item) async => null;

  @override
  void clearCache() {}
}

/// Запускает приложение с «настоящим» SharedPreferences из памяти.
/// В тестах вместо реального API подставляем тестовый репозиторий.
Future<void> pumpApp(
    WidgetTester tester, {
      bool onboarded = true,
      MediaRepository? repository,
    }) async {
  SharedPreferences.setMockInitialValues({'onboarded': onboarded});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      retry: noAutoRetry,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        mediaRepositoryProvider
            .overrideWithValue(repository ?? MockMediaRepository()),
      ],
      child: const NexoraApp(),
    ),
  );
}

/// Размер экрана как у телефона (около 411×891 dp).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('главная показывает загрузку, затем разделы', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // ждём загрузку главной
    await tester.pump();
    // Блок «Для вас» после загрузки делает свой запрос с задержкой 350 мс,
    // даём ему закончиться, иначе в конце теста останется висящий таймер
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Продолжить просмотр'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('первый запуск: приветствие, потом главная', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(tester, onboarded: false);

    expect(find.text('Nexora'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    await tester.tap(find.text('Пропустить'));
    await tester.pump(); // приложение заменяет приветствие на Главную
    await tester.pump(const Duration(seconds: 1)); // ждём тестовую задержку
    await tester.pump(const Duration(seconds: 1)); // запас на смену экрана
    await tester.pump();

    expect(find.text('Продолжить просмотр'), findsOneWidget);
  });

  testWidgets('каталог открывается и показывает карточки', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.desktop_windows_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Популярное'), findsOneWidget);
    expect(find.text('One Piece'), findsWidgets);
  });

  testWidgets('библиотека показывает записи, тайтл открывается', (tester) async {
    usePhoneScreen(tester);
    await pumpApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining('Смотрю'), findsWidgets);
    expect(find.text('One Piece'), findsOneWidget);

    await tester.tap(find.text('One Piece'));
    await tester.pumpAndSettle();

    expect(find.text('Описание'), findsOneWidget);
    // В библиотеке просмотрено 1142 серии, значит следующая 1143
    expect(find.text('Смотреть · серия 1143'), findsOneWidget);
  });

  testWidgets('при сбое сети главная показывает ошибку и «Повторить»',
          (tester) async {
        usePhoneScreen(tester);
        await pumpApp(tester, repository: FailingMediaRepository());
        await tester.pump();
        await tester.pump();

        expect(find.text('Нет соединения'), findsOneWidget);
        expect(find.text('Повторить'), findsOneWidget);
        expect(find.text('Продолжить просмотр'), findsNothing);
      });

  test('уровень и инициалы считаются правильно', () {
    final profile = ProfileState.initial();
    expect(profile.level, 17);
    expect(profile.xpInLevel, 1440);
    expect(initialsOf('Данияр Шабдарбай'), 'ДШ');
    expect(initialsOf('анна'), 'АН');
  });

  test('прогресс до конца завершает тайтл и начисляет очки', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final pointsBefore = container.read(profileProvider).points;

    container
        .read(libraryProvider.notifier)
        .setProgress(MockData.onePiece, MockData.onePiece.totalUnits);

    final entry = container.read(libraryProvider)[MockData.onePiece.id]!;
    expect(entry.status, LibraryStatus.completed);
    expect(container.read(profileProvider).points, greaterThan(pointsBefore));
  });
}