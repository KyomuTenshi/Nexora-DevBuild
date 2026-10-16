import 'package:flutter/services.dart';
import 'package:nexora/domain/entities/device_status.dart';
import 'package:nexora/domain/repositories/device_status_repository.dart';

/// Читает состояние устройства через собственный Platform Channel.
/// Нативная часть написана на Kotlin в MainActivity.kt.
class PlatformDeviceStatusRepository implements DeviceStatusRepository {
  PlatformDeviceStatusRepository({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  /// Имя должно совпадать с CHANNEL в MainActivity.kt
  static const channelName = 'com.piperitegames.nexora/device';

  final MethodChannel _channel;

  @override
  Future<DeviceStatus> read() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>(
        'getBatteryStatus',
      );
      if (map == null) return DeviceStatus.unknown;

      final level = map['level'];
      return DeviceStatus(
        batteryPercent: level is int && level >= 0 ? level : null,
        isCharging: map['charging'] == true,
        isPowerSaveMode: map['powerSave'] == true,
      );
    } on MissingPluginException {
      // Нативной части нет (iOS или тест): живём без этих данных
      return DeviceStatus.unknown;
    } on PlatformException {
      return DeviceStatus.unknown;
    }
  }
}
