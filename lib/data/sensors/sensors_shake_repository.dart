import 'dart:math';

import 'package:nexora/data/sensors/shake_detector.dart';
import 'package:nexora/domain/repositories/shake_repository.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Встряска по акселерометру без учёта силы тяжести.
class SensorsShakeRepository implements ShakeRepository {
  @override
  Stream<void> get shakes {
    // Датчик включается, только пока на поток кто-то подписан
    final magnitudes = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z));
    return detectShakes(magnitudes);
  }
}
