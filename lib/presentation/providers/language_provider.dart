import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/l10n/app_strings.dart';

/// Язык интерфейса. Запоминается между запусками в SharedPreferences.
class LanguageNotifier extends Notifier<AppLanguage> {
  static const _key = 'language';

  @override
  AppLanguage build() {
    final saved = ref.read(prefsProvider).getString(_key);
    return AppLanguage.values.firstWhere(
          (l) => l.name == saved,
      orElse: () => AppLanguage.ru,
    );
  }

  void set(AppLanguage language) {
    state = language;
    ref.read(prefsProvider).setString(_key, language.name);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(
  LanguageNotifier.new,
);

/// Строки на выбранном языке. Экраны берут их через ref.watch(stringsProvider).
final stringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(languageProvider));
});