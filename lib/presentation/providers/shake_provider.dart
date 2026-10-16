import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';

/// Включена ли функция «встряхни — случайный тайтл». Запоминается.
class ShakeEnabledNotifier extends Notifier<bool> {
  static const _key = 'shake_discover';

  @override
  bool build() => ref.read(prefsProvider).getBool(_key) ?? true;

  void setEnabled(bool value) {
    state = value;
    ref.read(prefsProvider).setBool(_key, value);
  }
}

final shakeEnabledProvider = NotifierProvider<ShakeEnabledNotifier, bool>(
  ShakeEnabledNotifier.new,
);
