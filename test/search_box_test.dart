import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/core/theme/app_theme.dart';
import 'package:nexora/data/repositories/mock_media_repository.dart';
import 'package:nexora/presentation/widgets/search_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('фокус открывает подсказки, ввод переключает на результаты',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

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
              home: const Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SearchBox(),
                  ),
                ),
              ),
            ),
          ),
        );

        // Панели нет, пока поле не в фокусе
        expect(find.text('Часто ищут'), findsNothing);

        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Часто ищут'), findsOneWidget);

        // Печатаем: подсказки уступают место результатам
        await tester.enterText(find.byType(TextField), 'One');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Часто ищут'), findsNothing);
      });
}