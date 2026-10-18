import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_unit.dart';

/// Ключ страницы списка: какой тайтл и какая по счёту страница (с нуля).
typedef UnitsPageKey = ({MediaItem item, int page});

/// Страница серий (глав) тайтла. Строки списка просят только нужную
/// страницу, поэтому длинный список не грузится целиком.
final unitsPageProvider = FutureProvider.family<UnitsPage, UnitsPageKey>(
  (ref, key) =>
      ref.watch(unitsRepositoryProvider).getUnits(key.item, page: key.page),
);

/// Сколько серий (глав) показывать. Берём большее из числа в карточке
/// тайтла и числа, которое знает сервер: у идущих аниме в карточке часто 0.
final unitsTotalProvider = Provider.family<int, MediaItem>((ref, item) {
  final first = ref.watch(unitsPageProvider((item: item, page: 0))).value;
  return math.max(item.totalUnits, first?.total ?? 0);
});

/// Данные об одной серии (главе) или null, пока страница грузится,
/// не загрузилась или записи в ней нет.
final unitProvider =
    Provider.family<MediaUnit?, ({MediaItem item, int number})>((ref, key) {
      final page = (key.number - 1) ~/ kUnitsPageSize;
      final data = ref
          .watch(unitsPageProvider((item: key.item, page: page)))
          .value;
      if (data == null) return null;
      for (final unit in data.items) {
        if (unit.number == key.number) return unit;
      }
      return null;
    });

/// Сколько страниц главы можно разом собрать для разбивки на тома.
/// У очень длинных тайтлов (сотни глав) тома не строим.
const int kMaxChaptersForVolumes = 600;

/// Все главы манги: нужны, чтобы собрать их по томам. Пустой список,
/// если глав нет или их слишком много.
final mangaChaptersProvider = FutureProvider.family<List<MediaUnit>, MediaItem>(
  (ref, item) async {
    final first = await ref.watch(
      unitsPageProvider((item: item, page: 0)).future,
    );
    if (first.total == 0 || first.total > kMaxChaptersForVolumes) {
      return first.items;
    }
    final pages = (first.total / kUnitsPageSize).ceil();
    final rest = await Future.wait([
      for (var p = 1; p < pages; p++)
        ref.read(unitsPageProvider((item: item, page: p)).future),
    ]);
    return [first, ...rest].expand((page) => page.items).toList();
  },
);

/// Главы, у которых известен том, сгруппированные по возрастанию тома.
/// Если томов нет вовсе, словарь пуст.
Map<int, List<MediaUnit>> groupByVolume(List<MediaUnit> chapters) {
  final result = <int, List<MediaUnit>>{};
  for (final chapter in chapters) {
    final volume = chapter.volume;
    if (volume == null) continue;
    result.putIfAbsent(volume, () => []).add(chapter);
  }
  final volumes = result.keys.toList()..sort();
  return {for (final v in volumes) v: result[v]!};
}
