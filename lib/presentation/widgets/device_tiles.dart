import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/device_provider.dart';
import 'package:nexora/presentation/providers/shake_provider.dart';

/// Показывает заряд и режим экономии, данные приходят из Kotlin-кода.
class DeviceStatusTile extends ConsumerWidget {
  const DeviceStatusTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceStatusProvider);

    final battery = device.batteryPercent == null
        ? 'Заряд неизвестен'
        : 'Заряд ${device.batteryPercent}%'
              '${device.isCharging ? ', идёт зарядка' : ''}';

    final mode = device.isPowerSaveMode
        ? 'Включено энергосбережение: карусель не листается сама'
        : device.isLowBattery
        ? 'Заряд низкий: карусель не листается сама'
        : 'Карусель на главной листается сама';

    final icon = device.isCharging
        ? Icons.battery_charging_full_rounded
        : device.isLowBattery
        ? Icons.battery_alert_rounded
        : Icons.battery_std_rounded;

    return ListTile(
      leading: Icon(icon),
      title: const Text('Батарея и энергосбережение'),
      subtitle: Text('$battery\n$mode'),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: 'Обновить',
        icon: const Icon(Icons.refresh_rounded),
        onPressed: () => ref.read(deviceStatusProvider.notifier).refresh(),
      ),
    );
  }
}

/// Переключатель «встряхни — случайный тайтл».
class ShakeTile extends ConsumerWidget {
  const ShakeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      secondary: const Icon(Icons.vibration_rounded),
      title: const Text('Встряхни — случайный тайтл'),
      subtitle: const Text('Работает на главных вкладках'),
      value: ref.watch(shakeEnabledProvider),
      onChanged: (value) =>
          ref.read(shakeEnabledProvider.notifier).setEnabled(value),
    );
  }
}
