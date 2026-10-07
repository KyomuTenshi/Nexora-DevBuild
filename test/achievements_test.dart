import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/data/repositories/in_memory_favorites_repository.dart';
import 'package:nexora/data/repositories/in_memory_library_repository.dart';
import 'package:nexora/data/repositories/in_memory_ratings_repository.dart';
import 'package:nexora/domain/entities/achievement.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/presentation/providers/achievements_provider.dart';
import 'package:nexora/presentation/providers/library_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

AchievementProgress _find(List<AchievementProgress> list, String id) =>
    list.firstWhere((p) => p.def.id == id);

Future<ProviderContainer> _makeContainer({required bool seeded}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      libraryRepositoryProvider
          .overrideWithValue(InMemoryLibraryRepository(seeded: seeded)),
      favoritesRepositoryProvider
          .overrideWithValue(InMemoryFavoritesRepository(seeded: seeded)),
      ratingsRepositoryProvider
          .overrideWithValue(InMemoryRatingsRepository(seeded: seeded)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Расчёт достижений', () {
    test('без активности ничего не открыто', () {
      final list = evaluateAchievements(const AchievementStats());
      expect(list.where((p) => p.unlocked), isEmpty);
    });

    test('прогресс считается и не выходит за цель', () {
      final list = evaluateAchievements(const AchievementStats(titles: 3));
      expect(_find(list, 'first_step').unlocked, isTrue);

      final collector = _find(list, 'collector');
      expect(collector.unlocked, isFalse);
      expect(collector.current, 3);
      expect(collector.fraction, closeTo(0.3, 0.001));

      final many = evaluateAchievements(const AchievementStats(titles: 99));
      expect(_find(many, 'collector').current, 10);
    });

    test('скрытое достижение открывается по двум условиям', () {
      final half = evaluateAchievements(const AchievementStats(animeCompleted: 1));
      expect(_find(half, 'double_life').unlocked, isFalse);

      final both = evaluateAchievements(
        const AchievementStats(animeCompleted: 1, mangaCompleted: 1),
      );
      expect(_find(both, 'double_life').unlocked, isTrue);
      expect(_find(both, 'double_life').def.hidden, isTrue);
    });
  });

  group('Выдача достижений', () {
    test('при запуске выполненное записывается тихо: без очков и плашки',
            () async {
          final container = await _makeContainer(seeded: true);
          final pointsBefore = container.read(profileProvider).points;

          final dates = container.read(achievementsProvider);

          expect(dates.containsKey('first_step'), isTrue);
          expect(container.read(profileProvider).points, pointsBefore);
          expect(container.read(achievementToastProvider), isEmpty);
        });

    test('новое достижение даёт очки и плашку', () async {
      final container = await _makeContainer(seeded: false);
      expect(container.read(achievementsProvider), isEmpty);
      final pointsBefore = container.read(profileProvider).points;

      container
          .read(libraryProvider.notifier)
          .setStatus(MockData.onePiece, LibraryStatus.planned);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(achievementsProvider).containsKey('first_step'),
          isTrue);
      expect(
        container.read(profileProvider).points,
        greaterThanOrEqualTo(pointsBefore + 50),
      );
      expect(
        container.read(achievementToastProvider).map((d) => d.id),
        contains('first_step'),
      );
    });

    test('закрепить можно не больше трёх достижений', () async {
      final container = await _makeContainer(seeded: false);
      final notifier = container.read(profileProvider.notifier);

      expect(notifier.togglePin('a'), isTrue);
      expect(notifier.togglePin('b'), isTrue);
      expect(notifier.togglePin('c'), isTrue);
      expect(notifier.togglePin('d'), isFalse);
      expect(container.read(profileProvider).pinned, ['a', 'b', 'c']);

      expect(notifier.togglePin('a'), isTrue); // открепление
      expect(container.read(profileProvider).pinned, ['b', 'c']);
    });
  });
}