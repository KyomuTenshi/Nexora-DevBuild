/// Витрины (блоки) профиля. Чистая модель без Flutter.
enum ShowcaseType {
  favoriteTitle,
  favorites,
  nowWatching,
  stats,
  ratings,
  genres,
}

extension ShowcaseInfo on ShowcaseType {
  String get title => switch (this) {
    ShowcaseType.favoriteTitle => 'Любимый тайтл',
    ShowcaseType.favorites => 'Любимое аниме и манга',
    ShowcaseType.nowWatching => 'Сейчас смотрю и читаю',
    ShowcaseType.stats => 'Статистика',
    ShowcaseType.ratings => 'Распределение оценок',
    ShowcaseType.genres => 'Любимые жанры',
  };

  String get description => switch (this) {
    ShowcaseType.favoriteTitle => 'Один главный тайтл с вашей оценкой',
    ShowcaseType.favorites => 'До трёх обложек из избранного',
    ShowcaseType.nowWatching => 'Что вы смотрите и читаете прямо сейчас',
    ShowcaseType.stats => 'Выберите, какие числа показать',
    ShowcaseType.ratings => 'Сколько пятёрок, четвёрок и так далее',
    ShowcaseType.genres => 'Жанры, которые вы выбрали в профиле',
  };

  /// Цена открытия в очках. 0 значит «открыто сразу».
  int get price => switch (this) {
    ShowcaseType.favorites => 0,
    ShowcaseType.stats => 0,
    ShowcaseType.genres => 250,
    ShowcaseType.favoriteTitle => 300,
    ShowcaseType.nowWatching => 400,
    ShowcaseType.ratings => 500,
  };

  /// Есть ли у витрины настройка (выбор тайтлов или чисел).
  bool get configurable =>
      this == ShowcaseType.favoriteTitle ||
          this == ShowcaseType.favorites ||
          this == ShowcaseType.stats;
}

/// Числа, которые можно вывести в витрине «Статистика».
enum StatKey { inLists, completed, favorites, rated, anime, manga, average }

extension StatKeyLabel on StatKey {
  String get label => switch (this) {
    StatKey.inLists => 'В списках',
    StatKey.completed => 'Завершено',
    StatKey.favorites => 'Избранное',
    StatKey.rated => 'Оценок',
    StatKey.anime => 'Аниме',
    StatKey.manga => 'Манга',
    StatKey.average => 'Средняя оценка',
  };
}

const int kMaxFavorites = 3;
const int kMaxStats = 4;

const List<ShowcaseType> kDefaultOrder = ShowcaseType.values;
const Set<ShowcaseType> kDefaultOwned = {
  ShowcaseType.favorites,
  ShowcaseType.stats,
};
const List<StatKey> kDefaultStatKeys = [
  StatKey.inLists,
  StatKey.completed,
  StatKey.favorites,
];

List<T> _enums<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! List) return [];
  return [
    for (final name in raw)
      for (final v in values)
        if (v.name == name) v,
  ];
}

/// Настройки страницы профиля: подписи шапки, порядок и выбор витрин,
/// переключатели приватности. Неизменяемый объект.
class ProfileLayout {
  const ProfileLayout({
    this.realName = '',
    this.location = '',
    this.status = '',
    this.order = kDefaultOrder,
    this.owned = kDefaultOwned,
    this.hidden = const {},
    this.favoriteTitleId = 0,
    this.favoriteIds = const [],
    this.statKeys = kDefaultStatKeys,
    this.showRealName = true,
    this.showLocation = true,
    this.showStatus = true,
    this.showLevel = true,
    this.showPresence = true,
    this.showSections = true,
  });

  final String realName;
  final String location;
  final String status;

  /// Порядок всех витрин (открытых и закрытых).
  final List<ShowcaseType> order;

  /// Какие витрины куплены.
  final Set<ShowcaseType> owned;

  /// Какие витрины владелец скрыл от показа.
  final Set<ShowcaseType> hidden;

  /// id любимого тайтла. 0 значит «не выбран».
  final int favoriteTitleId;
  final List<int> favoriteIds;
  final List<StatKey> statKeys;

  final bool showRealName;
  final bool showLocation;
  final bool showStatus;
  final bool showLevel;
  final bool showPresence;
  final bool showSections;

  bool isVisible(ShowcaseType t) => owned.contains(t) && !hidden.contains(t);

  /// Витрины, которые реально рисуются на странице, в нужном порядке.
  List<ShowcaseType> get shown => [
    for (final t in order)
      if (isVisible(t)) t,
  ];

  ProfileLayout copyWith({
    String? realName,
    String? location,
    String? status,
    List<ShowcaseType>? order,
    Set<ShowcaseType>? owned,
    Set<ShowcaseType>? hidden,
    int? favoriteTitleId,
    List<int>? favoriteIds,
    List<StatKey>? statKeys,
    bool? showRealName,
    bool? showLocation,
    bool? showStatus,
    bool? showLevel,
    bool? showPresence,
    bool? showSections,
  }) {
    return ProfileLayout(
      realName: realName ?? this.realName,
      location: location ?? this.location,
      status: status ?? this.status,
      order: order ?? this.order,
      owned: owned ?? this.owned,
      hidden: hidden ?? this.hidden,
      favoriteTitleId: favoriteTitleId ?? this.favoriteTitleId,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      statKeys: statKeys ?? this.statKeys,
      showRealName: showRealName ?? this.showRealName,
      showLocation: showLocation ?? this.showLocation,
      showStatus: showStatus ?? this.showStatus,
      showLevel: showLevel ?? this.showLevel,
      showPresence: showPresence ?? this.showPresence,
      showSections: showSections ?? this.showSections,
    );
  }

  Map<String, dynamic> toJson() => {
    'realName': realName,
    'location': location,
    'status': status,
    'order': [for (final t in order) t.name],
    'owned': [for (final t in owned) t.name],
    'hidden': [for (final t in hidden) t.name],
    'favoriteTitleId': favoriteTitleId,
    'favoriteIds': favoriteIds,
    'statKeys': [for (final k in statKeys) k.name],
    'showRealName': showRealName,
    'showLocation': showLocation,
    'showStatus': showStatus,
    'showLevel': showLevel,
    'showPresence': showPresence,
    'showSections': showSections,
  };

  /// Читаем осторожно: чего нет или что не того типа, берём по умолчанию.
  factory ProfileLayout.fromJson(Map<String, dynamic> j) {
    const d = ProfileLayout();

    // Порядок всегда содержит все витрины (на случай новых версий)
    final order = _enums(ShowcaseType.values, j['order']);
    for (final t in ShowcaseType.values) {
      if (!order.contains(t)) order.add(t);
    }

    final stats = _enums(StatKey.values, j['statKeys']);

    return ProfileLayout(
      realName: j['realName'] as String? ?? '',
      location: j['location'] as String? ?? '',
      status: j['status'] as String? ?? '',
      order: order,
      owned: j['owned'] == null
          ? d.owned
          : _enums(ShowcaseType.values, j['owned']).toSet(),
      hidden: _enums(ShowcaseType.values, j['hidden']).toSet(),
      favoriteTitleId: j['favoriteTitleId'] as int? ?? 0,
      favoriteIds: (j['favoriteIds'] as List<dynamic>? ?? const [])
          .whereType<int>()
          .toList(),
      statKeys: stats.isEmpty ? d.statKeys : stats,
      showRealName: j['showRealName'] as bool? ?? true,
      showLocation: j['showLocation'] as bool? ?? true,
      showStatus: j['showStatus'] as bool? ?? true,
      showLevel: j['showLevel'] as bool? ?? true,
      showPresence: j['showPresence'] as bool? ?? true,
      showSections: j['showSections'] as bool? ?? true,
    );
  }
}