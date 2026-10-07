import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/showcase.dart';
import 'package:nexora/presentation/providers/profile_layout_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('по умолчанию открыты «Любимое» и «Статистика»', () async {
    final c = await makeContainer();
    final layout = c.read(profileLayoutProvider);

    expect(layout.owned, {ShowcaseType.favorites, ShowcaseType.stats});
    expect(layout.shown, [ShowcaseType.favorites, ShowcaseType.stats]);
  });

  test('покупка списывает очки один раз', () async {
    final c = await makeContainer();
    final before = c.read(profileProvider).points;

    expect(c.read(profileLayoutProvider.notifier).buy(ShowcaseType.nowWatching),
        isTrue);
    expect(c.read(profileProvider).points,
        before - ShowcaseType.nowWatching.price);
    expect(c.read(profileLayoutProvider).owned,
        contains(ShowcaseType.nowWatching));

    // Повторно ничего не списывается
    c.read(profileLayoutProvider.notifier).buy(ShowcaseType.nowWatching);
    expect(c.read(profileProvider).points,
        before - ShowcaseType.nowWatching.price);
  });

  test('без очков витрину не купить', () async {
    final c = await makeContainer();
    c.read(profileProvider.notifier).edit((p) => p.copyWith(points: 10));

    expect(c.read(profileLayoutProvider.notifier).buy(ShowcaseType.ratings),
        isFalse);
    expect(c.read(profileProvider).points, 10);
    expect(c.read(profileLayoutProvider).owned,
        isNot(contains(ShowcaseType.ratings)));
  });

  test('перестановка меняет порядок только открытых витрин', () async {
    final c = await makeContainer();

    // Открытые: favorites, stats. Тянем первую в конец (индекс ReorderableListView = 2)
    c.read(profileLayoutProvider.notifier).reorderOwned(0, 2);

    expect(c.read(profileLayoutProvider).shown,
        [ShowcaseType.stats, ShowcaseType.favorites]);
    expect(c.read(profileLayoutProvider).order.length,
        ShowcaseType.values.length);
  });

  test('скрытая витрина не показывается', () async {
    final c = await makeContainer();
    c.read(profileLayoutProvider.notifier).setVisible(ShowcaseType.stats, false);

    expect(c.read(profileLayoutProvider).shown, [ShowcaseType.favorites]);
  });

  test('настройки переживают сохранение в JSON', () {
    final layout = const ProfileLayout().copyWith(
      realName: 'Данияр',
      favoriteIds: [3, 7],
      favoriteTitleId: 7,
      statKeys: [StatKey.average],
      hidden: {ShowcaseType.stats},
      showLevel: false,
    );

    final back = ProfileLayout.fromJson(
      jsonDecode(jsonEncode(layout.toJson())) as Map<String, dynamic>,
    );

    expect(back.realName, 'Данияр');
    expect(back.favoriteIds, [3, 7]);
    expect(back.favoriteTitleId, 7);
    expect(back.statKeys, [StatKey.average]);
    expect(back.hidden, {ShowcaseType.stats});
    expect(back.showLevel, isFalse);
  });

  test('старые переключатели профиля переносятся при первом запуске', () async {
    final old = ProfileState.initial().toJson()..['showStats'] = false;
    final c = await makeContainer({'profile_v1': jsonEncode(old)});

    final layout = c.read(profileLayoutProvider);
    expect(layout.hidden, contains(ShowcaseType.stats));
    expect(layout.shown, [ShowcaseType.favorites]);
  });
}