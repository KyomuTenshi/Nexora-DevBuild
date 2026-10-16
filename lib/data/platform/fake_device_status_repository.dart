import 'package:nexora/domain/entities/device_status.dart';
import 'package:nexora/domain/repositories/device_status_repository.dart';

/// Подставное состояние устройства для тестов (и значение по умолчанию в DI).
class FakeDeviceStatusRepository implements DeviceStatusRepository {
  FakeDeviceStatusRepository([this.status = DeviceStatus.unknown]);

  DeviceStatus status;

  @override
  Future<DeviceStatus> read() async => status;
}
