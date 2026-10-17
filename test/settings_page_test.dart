import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/device_providers.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/di/retry.dart';
import 'package:nexora/data/platform/fake_device_status_repository.dart';
import 'package:nexora/domain/entities/device_status.dart';
import 'package:nexora/presentation/pages/profile/settings_page.dart';
import 'package:nexora/presentation/providers/language_provider.dart';
import 'package:nexora/presentation/providers/shake_provider.dart';
import 'package:nexora/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Открывает экран настроек и возвращает хранилище настроек и контейнер
/// провайдеров, чтобы тест мог проверить состояние.
Future<(SharedPreferences, ProviderContainer)> pumpSettings(
  WidgetTester tester, {
  DeviceStatus? device,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  // Размер экрана как у телефона
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      retry: noAutoRetry,
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        if (device != null)
          deviceStatusRepositoryProvider.overrideWithValue(
            FakeDeviceStatusRepository(device),
          ),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  await tester.pump();

  final container = ProviderScope.containerOf(
    tester.element(find.byType(SettingsPage)),
  );
  return (prefs, container);
}

/// Прокручивает список настроек, пока нужный текст не появится на экране.
Future<void> scrollTo(WidgetTester tester, String text) async {
  await tester.scrollUntilVisible(
    find.text(text),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.pump(); // дочитать состояние устройства
}

void main() {
  testWidgets('экран показывает главные разделы', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Внешний вид'), findsOneWidget);
    for (final label in ['Тёмная', 'Светлая', 'Авто']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('смена темы применяется и запоминается', (tester) async {
    final (prefs, container) = await pumpSettings(tester);
    expect(container.read(themeProvider), ThemeMode.dark);

    await tester.tap(find.text('Светлая'));
    await tester.pump();

    expect(container.read(themeProvider), ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
  });

  testWidgets('смена языка переводит экран', (tester) async {
    final (prefs, container) = await pumpSettings(tester);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(container.read(languageProvider).name, 'en');
    expect(prefs.getString('language'), 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('переключатель встряски выключается и запоминается', (
    tester,
  ) async {
    final (prefs, container) = await pumpSettings(tester);
    await scrollTo(tester, 'Встряхни — случайный тайтл');
    expect(container.read(shakeEnabledProvider), isTrue);

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Встряхни — случайный тайтл'),
    );
    await tester.pump();

    expect(container.read(shakeEnabledProvider), isFalse);
    expect(prefs.getBool('shake_discover'), isFalse);
  });

  testWidgets('плитка батареи предупреждает о низком заряде', (tester) async {
    await pumpSettings(tester, device: const DeviceStatus(batteryPercent: 12));
    await scrollTo(tester, 'Батарея и энергосбережение');

    expect(find.textContaining('Заряд 12%'), findsOneWidget);
    expect(find.textContaining('Заряд низкий'), findsOneWidget);
  });

  testWidgets('плитка батареи показывает режим энергосбережения', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      device: const DeviceStatus(batteryPercent: 80, isPowerSaveMode: true),
    );
    await scrollTo(tester, 'Батарея и энергосбережение');

    expect(find.textContaining('Заряд 80%'), findsOneWidget);
    expect(find.textContaining('Включено энергосбережение'), findsOneWidget);
  });
}
