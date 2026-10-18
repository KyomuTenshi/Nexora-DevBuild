import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';

/// Режим разработчика. Обычному пользователю служебные пункты (проверка
/// Crashlytics, демо-экраны, сброс данных, токен push) не нужны, поэтому
/// они скрыты. Открываются семью нажатиями на строку с версией в настройках.
class DevModeNotifier extends Notifier<bool> {
  static const _key = 'dev_mode';

  /// Сколько нажатий на версию открывают режим.
  static const tapsToUnlock = 7;

  int _taps = 0;

  @override
  bool build() => ref.read(prefsProvider).getBool(_key) ?? false;

  /// Нажатие на строку с версией. Возвращает, сколько нажатий осталось
  /// (0 значит «режим только что включён»).
  int tapVersion() {
    if (state) return 0;
    _taps++;
    if (_taps >= tapsToUnlock) {
      _taps = 0;
      _set(true);
      return 0;
    }
    return tapsToUnlock - _taps;
  }

  void disable() => _set(false);

  void _set(bool value) {
    state = value;
    ref.read(prefsProvider).setBool(_key, value);
  }
}

final devModeProvider = NotifierProvider<DevModeNotifier, bool>(
  DevModeNotifier.new,
);
