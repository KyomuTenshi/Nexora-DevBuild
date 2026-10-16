import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/platform/fake_device_status_repository.dart';
import 'package:nexora/data/sensors/fake_shake_repository.dart';
import 'package:nexora/domain/repositories/device_status_repository.dart';
import 'package:nexora/domain/repositories/shake_repository.dart';

/// По умолчанию подставные реализации (тесты работают без телефона).
/// Настоящие подключаются в main().
final deviceStatusRepositoryProvider = Provider<DeviceStatusRepository>(
  (ref) => FakeDeviceStatusRepository(),
);

final shakeRepositoryProvider = Provider<ShakeRepository>(
  (ref) => FakeShakeRepository(),
);
