import 'dart:async';

import 'package:nexora/domain/repositories/shake_repository.dart';

/// «Встряхивание» кнопкой для тестов (и значение по умолчанию в DI).
class FakeShakeRepository implements ShakeRepository {
  final _controller = StreamController<void>.broadcast();

  void trigger() => _controller.add(null);

  @override
  Stream<void> get shakes => _controller.stream;
}
