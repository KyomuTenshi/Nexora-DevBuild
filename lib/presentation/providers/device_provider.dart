import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/device_providers.dart';
import 'package:nexora/domain/entities/device_status.dart';

/// Состояние устройства. Обновляется при старте и при каждом возврате
/// в приложение (человек мог включить экономию энергии в шторке).
class DeviceStatusNotifier extends Notifier<DeviceStatus> {
  @override
  DeviceStatus build() {
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);
    refresh();
    return DeviceStatus.unknown;
  }

  Future<void> refresh() async {
    final status = await ref.read(deviceStatusRepositoryProvider).read();
    // Пока ждали ответ, провайдер мог быть уничтожен
    if (ref.mounted) state = status;
  }
}

final deviceStatusProvider =
    NotifierProvider<DeviceStatusNotifier, DeviceStatus>(
      DeviceStatusNotifier.new,
    );
