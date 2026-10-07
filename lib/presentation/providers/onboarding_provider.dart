import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';

/// Прошёл ли пользователь приветствие. Хранится в SharedPreferences.
class OnboardedNotifier extends Notifier<bool> {
  static const _key = 'onboarded';

  @override
  bool build() => ref.read(prefsProvider).getBool(_key) ?? false;

  void complete() {
    state = true;
    ref.read(prefsProvider).setBool(_key, true);
  }

  /// Для кнопки «Показать приветствие снова» в настройках.
  void reset() {
    state = false;
    ref.read(prefsProvider).setBool(_key, false);
  }
}

final onboardedProvider = NotifierProvider<OnboardedNotifier, bool>(
  OnboardedNotifier.new,
);
