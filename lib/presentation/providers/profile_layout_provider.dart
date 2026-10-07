import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/showcase.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

class ProfileLayoutNotifier extends Notifier<ProfileLayout> {
  static const _key = 'profile_layout_v1';

  @override
  ProfileLayout build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw != null) {
      try {
        return ProfileLayout.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Повреждённые данные: начинаем с настроек по умолчанию.
      }
    }

    // Первый запуск: переносим старые переключатели из прежнего профиля
    final old = ref.read(profileProvider);
    return ProfileLayout(
      hidden: {
        if (!old.showFavorites) ShowcaseType.favorites,
        if (!old.showStats) ShowcaseType.stats,
      },
    );
  }

  void _commit(ProfileLayout next) {
    state = next;
    ref.read(prefsProvider).setString(_key, jsonEncode(next.toJson()));
  }

  /// Применить любое изменение настроек и сохранить.
  void edit(ProfileLayout Function(ProfileLayout current) change) =>
      _commit(change(state));

  /// Открыть витрину за очки. Возвращает false, если очков не хватает.
  /// Повторная покупка ничего не стоит.
  bool buy(ShowcaseType type) {
    if (state.owned.contains(type)) return true;
    final points = ref.read(profileProvider).points;
    if (points < type.price) return false;

    ref
        .read(profileProvider.notifier)
        .edit((p) => p.copyWith(points: p.points - type.price));
    _commit(state.copyWith(
      owned: {...state.owned, type},
      hidden: {...state.hidden}..remove(type),
    ));
    return true;
  }

  void setVisible(ShowcaseType type, bool visible) {
    final hidden = {...state.hidden};
    if (visible) {
      hidden.remove(type);
    } else {
      hidden.add(type);
    }
    _commit(state.copyWith(hidden: hidden));
  }

  /// Перестановка среди открытых витрин.
  void reorderOwned(int oldIndex, int newIndex) {
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    final owned = [
      for (final t in state.order)
        if (state.owned.contains(t)) t,
    ];
    final rest = [
      for (final t in state.order)
        if (!state.owned.contains(t)) t,
    ];
    final moved = owned.removeAt(oldIndex);
    owned.insert(targetIndex, moved);
    _commit(state.copyWith(order: [...owned, ...rest]));
  }
}

final profileLayoutProvider =
NotifierProvider<ProfileLayoutNotifier, ProfileLayout>(
  ProfileLayoutNotifier.new,
);