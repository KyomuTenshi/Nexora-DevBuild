import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

/// Библиотека пользователя: id тайтла -> запись.
/// Состояние обновляется сразу (оптимистично), а хранилище догоняет следом.
class LibraryNotifier extends Notifier<Map<int, LibraryEntry>> {
  @override
  Map<int, LibraryEntry> build() {
    final repository = ref.read(libraryRepositoryProvider);
    return {for (final e in repository.getAll()) e.item.id: e};
  }

  /// Положить тайтл в список или перенести в другой.
  void setStatus(MediaItem item, LibraryStatus status) {
    var progress = state[item.id]?.progress ?? 0;
    if (status == LibraryStatus.completed && item.totalUnits > 0) {
      progress = item.totalUnits;
    }
    _save(LibraryEntry(
      item: item,
      status: status,
      progress: progress,
      updatedAt: DateTime.now(),
    ));
  }

  /// Отметить, сколько серий (глав) пройдено. За новые серии даём очки.
  void setProgress(MediaItem item, int value) {
    final old = state[item.id];
    final max = item.totalUnits > 0 ? item.totalUnits : 1000000;
    final progress = value < 0 ? 0 : (value > max ? max : value);
    final oldProgress = old?.progress ?? 0;

    var status = old?.status ?? LibraryStatus.inProgress;
    if (item.totalUnits > 0 && progress >= item.totalUnits) {
      status = LibraryStatus.completed;
    } else if (progress > 0 &&
        (status == LibraryStatus.completed || status == LibraryStatus.planned)) {
      status = LibraryStatus.inProgress;
    }

    _save(LibraryEntry(
      item: item,
      status: status,
      progress: progress,
      updatedAt: DateTime.now(),
    ));

    final delta = progress - oldProgress;
    if (delta > 0) {
      final perUnit = item.type == MediaType.anime ? 10 : 20;
      // Не больше 10 единиц за раз, чтобы нельзя было накрутить очки одним тапом.
      var reward = (delta > 10 ? 10 : delta) * perUnit;
      // Бонус за завершённый тайтл
      if (status == LibraryStatus.completed &&
          old?.status != LibraryStatus.completed) {
        reward += 100;
      }
      ref.read(profileProvider.notifier).earn(reward);
    }
  }

  void remove(int itemId) {
    state = {...state}..remove(itemId);
    unawaited(ref.read(libraryRepositoryProvider).remove(itemId));
  }

  void _save(LibraryEntry entry) {
    state = {...state, entry.item.id: entry};
    unawaited(ref.read(libraryRepositoryProvider).upsert(entry));
  }
}

final libraryProvider =
    NotifierProvider<LibraryNotifier, Map<int, LibraryEntry>>(
  LibraryNotifier.new,
);
