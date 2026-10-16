import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/device_providers.dart';
import 'package:nexora/core/di/retry.dart';
import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/data/platform/fake_device_status_repository.dart';
import 'package:nexora/data/platform/platform_device_status_repository.dart';
import 'package:nexora/domain/entities/device_status.dart';
import 'package:nexora/domain/entities/home_feed.dart';
import 'package:nexora/presentation/pages/home/featured_carousel.dart';
import 'package:nexora/presentation/providers/device_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceStatus', () {
    test('неизвестное состояние не требует экономии', () {
      expect(DeviceStatus.unknown.isLowBattery, isFalse);
      expect(DeviceStatus.unknown.shouldSaveEnergy, isFalse);
    });

    test('низкий заряд без зарядки включает экономию', () {
      const low = DeviceStatus(batteryPercent: 15);
      expect(low.isLowBattery, isTrue);
      expect(low.shouldSaveEnergy, isTrue);
    });

    test('на зарядке или при заряде выше порога экономия не нужна', () {
      expect(
        const DeviceStatus(
          batteryPercent: 5,
          isCharging: true,
        ).shouldSaveEnergy,
        isFalse,
      );
      expect(const DeviceStatus(batteryPercent: 16).shouldSaveEnergy, isFalse);
    });

    test('режим энергосбережения включает экономию при любом заряде', () {
      const status = DeviceStatus(batteryPercent: 90, isPowerSaveMode: true);
      expect(status.shouldSaveEnergy, isTrue);
    });

    test('равные состояния равны', () {
      expect(
        const DeviceStatus(batteryPercent: 50),
        const DeviceStatus(batteryPercent: 50),
      );
      expect(
        const DeviceStatus(batteryPercent: 50),
        isNot(const DeviceStatus(batteryPercent: 51)),
      );
    });
  });

  group('PlatformDeviceStatusRepository (канал)', () {
    const channel = MethodChannel(PlatformDeviceStatusRepository.channelName);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('разбирает ответ нативного кода', () async {
      String? calledMethod;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calledMethod = call.method;
        return <String, Object?>{
          'level': 42,
          'charging': true,
          'powerSave': false,
        };
      });

      final status = await PlatformDeviceStatusRepository().read();

      expect(calledMethod, 'getBatteryStatus');
      expect(status.batteryPercent, 42);
      expect(status.isCharging, isTrue);
      expect(status.isPowerSaveMode, isFalse);
    });

    test('уровень -1 означает «неизвестно»', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return <String, Object?>{
          'level': -1,
          'charging': false,
          'powerSave': true,
        };
      });

      final status = await PlatformDeviceStatusRepository().read();

      expect(status.batteryPercent, isNull);
      expect(status.isPowerSaveMode, isTrue);
    });

    test('ошибка платформы даёт неизвестное состояние', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'BATTERY_ERROR');
      });

      expect(
        await PlatformDeviceStatusRepository().read(),
        DeviceStatus.unknown,
      );
    });

    test('без нативной части (iOS, тест) приложение не падает', () async {
      expect(
        await PlatformDeviceStatusRepository().read(),
        DeviceStatus.unknown,
      );
    });
  });

  group('deviceStatusProvider', () {
    test('читает состояние при старте и по refresh()', () async {
      final repo = FakeDeviceStatusRepository(
        const DeviceStatus(batteryPercent: 10),
      );
      final container = ProviderContainer(
        retry: noAutoRetry,
        overrides: [deviceStatusRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(deviceStatusProvider, (_, _) {});

      expect(container.read(deviceStatusProvider), DeviceStatus.unknown);
      await pumpEventQueue();
      expect(container.read(deviceStatusProvider).batteryPercent, 10);

      repo.status = const DeviceStatus(batteryPercent: 80, isCharging: true);
      await container.read(deviceStatusProvider.notifier).refresh();
      expect(container.read(deviceStatusProvider).batteryPercent, 80);
      expect(container.read(deviceStatusProvider).isCharging, isTrue);
    });
  });

  group('FeaturedCarousel и экономия энергии', () {
    final banners = [
      const FeaturedBanner(
        item: MockData.jujutsu,
        badge: 'Новый сезон',
        caption: '2020',
      ),
      const FeaturedBanner(
        item: MockData.onePiece,
        badge: 'В эфире',
        caption: '1999',
      ),
    ];

    Future<void> pumpCarousel(WidgetTester tester, DeviceStatus status) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          retry: noAutoRetry,
          overrides: [
            deviceStatusRepositoryProvider.overrideWithValue(
              FakeDeviceStatusRepository(status),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: FeaturedCarousel(banners: banners),
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // состояние устройства подгрузилось
    }

    double dotWidth(WidgetTester tester, int i) =>
        tester.getSize(find.byKey(ValueKey('dot_$i'))).width;

    testWidgets('в обычном режиме листается само', (tester) async {
      await pumpCarousel(tester, DeviceStatus.unknown);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(
        dotWidth(tester, 1),
        20,
      ); // активная точка переехала на второй слайд
    });

    testWidgets('при энергосбережении само не листается', (tester) async {
      await pumpCarousel(
        tester,
        const DeviceStatus(batteryPercent: 80, isPowerSaveMode: true),
      );

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(dotWidth(tester, 0), 20); // остались на первом слайде
    });
  });
}
