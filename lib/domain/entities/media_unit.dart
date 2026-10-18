/// Сколько серий (глав) приходит за один запрос.
const int kUnitsPageSize = 20;

/// Одна серия аниме или одна глава манги. «Чистая» модель без Flutter и JSON.
class MediaUnit {
  const MediaUnit({
    required this.number,
    this.title,
    this.volume,
    this.thumbnailUrl,
    this.minutes,
    this.date,
  });

  final int number;

  /// Название серии (главы). null значит «названия нет».
  final String? title;

  /// Номер тома. Только у глав манги, и то не всегда.
  final int? volume;
  final String? thumbnailUrl;

  /// Длительность серии в минутах.
  final int? minutes;

  /// Дата выхода в формате «2021-04-02».
  final String? date;
}

/// Одна страница списка серий (глав) и общее число записей на сервере.
class UnitsPage {
  const UnitsPage({required this.items, required this.total});

  final List<MediaUnit> items;
  final int total;
}
