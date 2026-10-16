/// Состояние устройства, которое влияет на поведение приложения.
class DeviceStatus {
  const DeviceStatus({
    this.batteryPercent,
    this.isCharging = false,
    this.isPowerSaveMode = false,
  });

  /// Когда состояние узнать не удалось (iOS, ошибка канала, тесты)
  static const unknown = DeviceStatus();

  /// Заряд в процентах или null, если неизвестен
  final int? batteryPercent;
  final bool isCharging;
  final bool isPowerSaveMode;

  /// Заряд низкий, и телефон не на зарядке
  bool get isLowBattery {
    final percent = batteryPercent;
    return percent != null && percent <= 15 && !isCharging;
  }

  /// Нужно ли экономить энергию (отключать автоматические анимации)
  bool get shouldSaveEnergy => isPowerSaveMode || isLowBattery;

  @override
  bool operator ==(Object other) =>
      other is DeviceStatus &&
      other.batteryPercent == batteryPercent &&
      other.isCharging == isCharging &&
      other.isPowerSaveMode == isPowerSaveMode;

  @override
  int get hashCode => Object.hash(batteryPercent, isCharging, isPowerSaveMode);
}
