import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Оценки пользователя: id тайтла -> от 1 до 5.
class RatingsNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => const {2: 4};

  /// value == 0 снимает оценку.
  void set(int id, int value) {
    if (value <= 0) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id: value};
    }
  }
}

final ratingsProvider = NotifierProvider<RatingsNotifier, Map<int, int>>(
  RatingsNotifier.new,
);
