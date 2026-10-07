import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/l10n/app_strings.dart';
import 'package:nexora/presentation/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('по умолчанию интерфейс русский', () async {
    final c = await _container({});

    expect(c.read(languageProvider), AppLanguage.ru);
    expect(c.read(stringsProvider).navHome, 'Главная');
  });

  test('выбранный язык меняет строки и сохраняется', () async {
    final c = await _container({});

    c.read(languageProvider.notifier).set(AppLanguage.en);

    expect(c.read(stringsProvider).navHome, 'Home');
    expect(c.read(stringsProvider).level(3, '10', '100'), 'Level 3 · 10 / 100 XP');

    // «Перезапуск»: новый контейнер читает тот же SharedPreferences
    final prefs = c.read(prefsProvider);
    final second = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(second.dispose);
    expect(second.read(languageProvider), AppLanguage.en);
  });

  test('неизвестное сохранённое значение заменяется русским', () async {
    final c = await _container({'language': 'fr'});

    expect(c.read(languageProvider), AppLanguage.ru);
  });
}