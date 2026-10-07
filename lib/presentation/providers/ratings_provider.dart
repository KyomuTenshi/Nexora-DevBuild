import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';

/// Оценки пользователя: id тайтла -> от 1 до 5.
/// Состояние обновляется сразу (оптимистично), а хранилище догоняет следом.
class RatingsNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => ref.read(ratingsRepositoryProvider).getAll();

  /// value == 0 снимает оценку.
  void set(int id, int value) {
    final repository = ref.read(ratingsRepositoryProvider);
    if (value <= 0) {
      state = {...state}..remove(id);
      unawaited(repository.remove(id));
    } else {
      state = {...state, id: value};
      unawaited(repository.set(id, value));
    }
  }
}

final ratingsProvider = NotifierProvider<RatingsNotifier, Map<int, int>>(
  RatingsNotifier.new,
);