import 'dart:math' as math;

/// Редкость достижения. Чем реже, тем больше очков.
enum AchievementRarity {
  common('Обычное', 50),
  rare('Редкое', 100),
  epic('Эпическое', 250),
  legendary('Легендарное', 500);

  const AchievementRarity(this.label, this.points);

  final String label;
  final int points;
}

/// Сводка действий пользователя, по которой считаются достижения.
class AchievementStats {
  const AchievementStats({
    this.titles = 0,
    this.completed = 0,
    this.animeCompleted = 0,
    this.mangaCompleted = 0,
    this.episodes = 0,
    this.chapters = 0,
    this.favorites = 0,
    this.ratings = 0,
    this.genres = 0,
  });

  final int titles;
  final int completed;
  final int animeCompleted;
  final int mangaCompleted;
  final int episodes;
  final int chapters;
  final int favorites;
  final int ratings;
  final int genres;
}

/// Описание достижения. Чистая модель без Flutter: иконки и цвета
/// подбирает слой представления по id и редкости.
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.rarity,
    required this.target,
    required this.value,
    this.hidden = false,
  });

  final String id;
  final String title;
  final String description;
  final AchievementRarity rarity;

  /// Сколько нужно набрать для получения.
  final int target;

  /// Текущее значение из статистики.
  final int Function(AchievementStats stats) value;

  /// Скрытое достижение: пока не получено, название и условие не видны.
  final bool hidden;

  int get points => rarity.points;
}

/// Прогресс по одному достижению.
class AchievementProgress {
  AchievementProgress(this.def, int value)
      : current = value < 0 ? 0 : (value > def.target ? def.target : value);

  final AchievementDef def;

  /// Текущее значение, не больше цели.
  final int current;

  bool get unlocked => current >= def.target;
  double get fraction => current / def.target;
}

final List<AchievementDef> kAchievements = [
  AchievementDef(
    id: 'first_step',
    title: 'Первый шаг',
    description: 'Добавьте тайтл в библиотеку',
    rarity: AchievementRarity.common,
    target: 1,
    value: (s) => s.titles,
  ),
  AchievementDef(
    id: 'collector',
    title: 'Коллекционер',
    description: 'Соберите 10 тайтлов в библиотеке',
    rarity: AchievementRarity.rare,
    target: 10,
    value: (s) => s.titles,
  ),
  AchievementDef(
    id: 'archivist',
    title: 'Архивариус',
    description: 'Соберите 25 тайтлов в библиотеке',
    rarity: AchievementRarity.epic,
    target: 25,
    value: (s) => s.titles,
  ),
  AchievementDef(
    id: 'finisher',
    title: 'Финишная прямая',
    description: 'Завершите первый тайтл',
    rarity: AchievementRarity.common,
    target: 1,
    value: (s) => s.completed,
  ),
  AchievementDef(
    id: 'marathoner',
    title: 'Марафонец',
    description: 'Завершите 5 тайтлов',
    rarity: AchievementRarity.rare,
    target: 5,
    value: (s) => s.completed,
  ),
  AchievementDef(
    id: 'bookworm',
    title: 'Книжный червь',
    description: 'Прочитайте первую главу манги',
    rarity: AchievementRarity.common,
    target: 1,
    value: (s) => s.chapters,
  ),
  AchievementDef(
    id: 'reader',
    title: 'Читатель',
    description: 'Прочитайте 100 глав',
    rarity: AchievementRarity.rare,
    target: 100,
    value: (s) => s.chapters,
  ),
  AchievementDef(
    id: 'librarian',
    title: 'Хранитель свитков',
    description: 'Прочитайте 1000 глав',
    rarity: AchievementRarity.epic,
    target: 1000,
    value: (s) => s.chapters,
  ),
  AchievementDef(
    id: 'viewer',
    title: 'Зритель',
    description: 'Посмотрите 100 серий',
    rarity: AchievementRarity.rare,
    target: 100,
    value: (s) => s.episodes,
  ),
  AchievementDef(
    id: 'otaku',
    title: 'Настоящий отаку',
    description: 'Посмотрите 2500 серий',
    rarity: AchievementRarity.legendary,
    target: 2500,
    value: (s) => s.episodes,
  ),
  AchievementDef(
    id: 'critic',
    title: 'Критик',
    description: 'Поставьте первую оценку',
    rarity: AchievementRarity.common,
    target: 1,
    value: (s) => s.ratings,
  ),
  AchievementDef(
    id: 'judge',
    title: 'Строгий судья',
    description: 'Оцените 10 тайтлов',
    rarity: AchievementRarity.rare,
    target: 10,
    value: (s) => s.ratings,
  ),
  AchievementDef(
    id: 'favorite',
    title: 'Любимчик',
    description: 'Добавьте 3 тайтла в избранное',
    rarity: AchievementRarity.common,
    target: 3,
    value: (s) => s.favorites,
  ),
  AchievementDef(
    id: 'heart',
    title: 'Сердце коллекции',
    description: 'Добавьте 10 тайтлов в избранное',
    rarity: AchievementRarity.rare,
    target: 10,
    value: (s) => s.favorites,
  ),
  AchievementDef(
    id: 'explorer',
    title: 'Всеядный',
    description: 'Соберите тайтлы пяти разных жанров',
    rarity: AchievementRarity.rare,
    target: 5,
    value: (s) => s.genres,
  ),
  AchievementDef(
    id: 'double_life',
    title: 'Двойная жизнь',
    description: 'Завершите и аниме, и мангу',
    rarity: AchievementRarity.epic,
    target: 2,
    hidden: true,
    value: (s) =>
    (s.animeCompleted > 0 ? 1 : 0) + (s.mangaCompleted > 0 ? 1 : 0),
  ),
  AchievementDef(
    id: 'perfectionist',
    title: 'Перфекционист',
    description: 'Завершите, оцените и добавьте в избранное по 3 тайтла',
    rarity: AchievementRarity.legendary,
    target: 3,
    hidden: true,
    value: (s) => math.min(s.completed, math.min(s.ratings, s.favorites)),
  ),
];

/// Считает прогресс по всем достижениям. Чистая функция: её легко тестировать.
List<AchievementProgress> evaluateAchievements(AchievementStats stats) => [
  for (final def in kAchievements)
    AchievementProgress(def, def.value(stats)),
];