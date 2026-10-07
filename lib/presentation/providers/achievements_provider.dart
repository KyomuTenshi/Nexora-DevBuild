import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/achievement.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/favorites_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/ratings_provider.dart';

/// Сводка действий пользователя: считается из библиотеки, избранного и оценок.
final achievementStatsProvider = Provider<AchievementStats>((ref) {
  final library = ref.watch(libraryProvider).values;
  final favorites = ref.watch(favoritesProvider);
  final ratings = ref.watch(ratingsProvider);

  var episodes = 0;
  var chapters = 0;
  var completed = 0;
  var animeCompleted = 0;
  var mangaCompleted = 0;
  final genres = <String>{};

  for (final entry in library) {
    final isAnime = entry.item.type == MediaType.anime;
    if (isAnime) {
      episodes += entry.progress;
    } else {
      chapters += entry.progress;
    }
    if (entry.status == LibraryStatus.completed) {
      completed++;
      if (isAnime) {
        animeCompleted++;
      } else {
        mangaCompleted++;
      }
    }
    genres.addAll(entry.item.genres);
  }

  return AchievementStats(
    titles: library.length,
    completed: completed,
    animeCompleted: animeCompleted,
    mangaCompleted: mangaCompleted,
    episodes: episodes,
    chapters: chapters,
    favorites: favorites.length,
    ratings: ratings.length,
    genres: genres.length,
  );
});

/// Прогресс по всем достижениям (пересчитывается при любом действии).
final achievementProgressProvider = Provider<List<AchievementProgress>>((ref) {
  return evaluateAchievements(ref.watch(achievementStatsProvider));
});

/// Какие достижения получены и когда: id -> время в миллисекундах.
/// Полученное остаётся навсегда, даже если потом тайтл удалят из библиотеки.
class AchievementsNotifier extends Notifier<Map<String, int>> {
  static const _key = 'achievements_v1';

  @override
  Map<String, int> build() {
    final prefs = ref.read(prefsProvider);
    final raw = prefs.getString(_key);
    final stored = _decode(raw);
    final now = DateTime.now().millisecondsSinceEpoch;

    // То, что выполнено уже при запуске, записываем тихо: без очков и плашки.
    // Иначе при первом запуске посыпались бы уведомления за демо-данные.
    final merged = {...stored};
    for (final p in ref.read(achievementProgressProvider)) {
      if (p.unlocked) merged.putIfAbsent(p.def.id, () => now);
    }
    if (raw == null || merged.length != stored.length) {
      unawaited(prefs.setString(_key, jsonEncode(merged)));
    }

    // Дальше следим за действиями пользователя
    ref.listen(achievementProgressProvider, (_, next) => _onProgress(next));
    return merged;
  }

  void _onProgress(List<AchievementProgress> list) {
    final fresh = [
      for (final p in list)
        if (p.unlocked && !state.containsKey(p.def.id)) p.def,
    ];
    if (fresh.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    state = {...state, for (final d in fresh) d.id: now};
    unawaited(ref.read(prefsProvider).setString(_key, jsonEncode(state)));

    // Награда очками и плашка «Достижение получено»
    ref
        .read(profileProvider.notifier)
        .earn(fresh.fold<int>(0, (sum, d) => sum + d.points));
    ref.read(achievementToastProvider.notifier).push(fresh);
  }

  static Map<String, int> _decode(String? raw) {
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in json.entries)
          if (e.value is int) e.key: e.value as int,
      };
    } catch (_) {
      return {};
    }
  }
}

final achievementsProvider =
NotifierProvider<AchievementsNotifier, Map<String, int>>(
  AchievementsNotifier.new,
);

/// Очередь плашек «Достижение получено». Показывается по одной.
class AchievementToastNotifier extends Notifier<List<AchievementDef>> {
  @override
  List<AchievementDef> build() => const [];

  void push(List<AchievementDef> items) => state = [...state, ...items];

  void pop() {
    if (state.isNotEmpty) state = state.sublist(1);
  }
}

final achievementToastProvider =
NotifierProvider<AchievementToastNotifier, List<AchievementDef>>(
  AchievementToastNotifier.new,
);