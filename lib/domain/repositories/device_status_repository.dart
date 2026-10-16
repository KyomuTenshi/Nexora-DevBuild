import 'package:nexora/domain/entities/device_status.dart';

/// Откуда приложение узнаёт состояние устройства.
abstract interface class DeviceStatusRepository {
  Future<DeviceStatus> read();
}
