import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexora/app.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/di/retry.dart';
import 'package:nexora/data/repositories/mock_media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Запускает приложение целиком, но без сети и Firebase:
/// каталог подменён тестовыми данными.
Future<void> launchApp(WidgetTester tester, {bool onboarded = true}) async {
  SharedPreferences.setMockInitialValues({'onboarded': onboarded});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      retry: noAutoRetry,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        mediaRepositoryProvider.overrideWithValue(
          MockMediaRepository(
            homeDelay: const Duration(milliseconds: 100),
            searchDelay: const Duration(milliseconds: 100),
          ),
        ),
      ],
      child: const NexoraApp(),
    ),
  );
  await tester.pump();
}

/// На настоящем устройстве время идёт по-настоящему, поэтому вместо
/// pumpAndSettle ждём появления нужного элемента.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Не дождались: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('первый запуск: приветствие, главная, каталог, тайтл и назад', (
    tester,
  ) async {
    await launchApp(tester, onboarded: false);

    // 1. Приветствие, пропускаем его
    await waitFor(tester, find.text('Пропустить'));
    await tester.tap(find.text('Пропустить'));

    // 2. Главная загрузилась
    await waitFor(tester, find.text('Продолжить просмотр'));
    expect(find.byType(NavigationBar), findsOneWidget);

    // 3. Каталог со списком карточек
    await tester.tap(find.byIcon(Icons.desktop_windows_outlined));
    await waitFor(tester, find.text('Популярное'));
    await waitFor(tester, find.text('One Piece'));

    // 4. Страница тайтла: в библиотеке 1142 серии, значит следующая 1143
    await tester.tap(find.text('One Piece').first);
    await waitFor(tester, find.text('Смотреть · серия 1143'));

    // 5. Назад в каталог
    await tester.pageBack();
    await waitFor(tester, find.text('Популярное'));
  });

  testWidgets('настройки: тема и язык меняются на лету', (tester) async {
    await launchApp(tester);
    await waitFor(tester, find.text('Продолжить просмотр'));

    // Меню, затем «Настройки»
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Меню'),
      ),
    );
    await waitFor(tester, find.text('Настройки'));
    await tester.ensureVisible(find.text('Настройки'));
    await tester.tap(find.text('Настройки'));
    await waitFor(tester, find.text('Внешний вид'));

    // Тема по умолчанию тёмная; переключаем на светлую
    final scaffold = find.byType(Scaffold).first;
    expect(Theme.of(tester.element(scaffold)).brightness, Brightness.dark);
    await tester.tap(find.text('Светлая'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Theme.of(tester.element(scaffold)).brightness, Brightness.light);

    // Язык: заголовок экрана становится английским
    await tester.tap(find.text('English'));
    await waitFor(tester, find.text('Appearance'));
    expect(find.text('Settings'), findsWidgets);
  });
}
