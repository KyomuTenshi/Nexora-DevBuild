import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/core/theme/app_theme.dart';
import 'package:nexora/data/repositories/mock_media_repository.dart';
import 'package:nexora/domain/entities/catalog_query.dart';
import 'package:nexora/presentation/pages/menu/menu_page.dart';
import 'package:nexora/presentation/providers/catalog_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpMenu(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  // Размер экрана как у телефона
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        mediaRepositoryProvider.overrideWithValue(
          MockMediaRepository(
            homeDelay: Duration.zero,
            searchDelay: Duration.zero,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(AppColors.primary),
        home: const MenuPage(),
      ),
    ),
  );
}

void main() {
  testWidgets('меню показывает разделы как в Steam', (tester) async {
    await pumpMenu(tester);

    expect(find.text('Меню'), findsOneWidget);
    for (final title in [
      'Каталог',
      'Новинки',
      'Уведомления',
      'Библиотека',
      'Избранное',
      'Достижения',
      'Магазин очков',
      'Настройки',
      'Поддержка',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('раздел «Каталог» раскрывается и открывает нужную категорию',
          (tester) async {
        await pumpMenu(tester);

        expect(find.text('Сейчас выходит'), findsNothing);
        await tester.tap(find.text('Каталог'));
        await tester.pumpAndSettle();
        expect(find.text('Сейчас выходит'), findsOneWidget);

        await tester.tap(find.text('Сейчас выходит'));
        await tester.pump();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MenuPage)),
        );
        expect(container.read(catalogQueryProvider).category,
            CatalogCategory.airing);
        expect(container.read(shellTabProvider), 1); // открылся каталог
      });

  testWidgets('карточка пользователя открывает профиль отдельной страницей',
          (tester) async {
        await pumpMenu(tester);

        await tester.tap(find.text('Данияр'));
        await tester.pumpAndSettle();

        expect(find.text('Редактировать профиль'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Редактировать профиль'), findsNothing);
      });
}