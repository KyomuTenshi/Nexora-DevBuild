import 'media_item.dart';

enum LibraryStatus { inProgress, paused, completed, planned, dropped }

/// Запись пользователя в библиотеке: тайтл, список и сколько серий/глав пройдено.
class LibraryEntry {
  const LibraryEntry({
    required this.item,
    required this.status,
    required this.progress,
    required this.updatedAt,
  });

  final MediaItem item;
  final LibraryStatus status;

  /// Сколько серий (глав) уже просмотрено (прочитано).
  final int progress;
  final DateTime updatedAt;

  /// Номер следующей серии (главы), которую пользователь будет смотреть.
  int get next {
    if (item.totalUnits == 0) return progress + 1;
    return progress >= item.totalUnits ? item.totalUnits : progress + 1;
  }

  /// Доля пройденного от 0.0 до 1.0
  double get fraction => item.totalUnits == 0
      ? 0.0
      : (progress / item.totalUnits).clamp(0.0, 1.0);

  LibraryEntry copyWith({
    LibraryStatus? status,
    int? progress,
    DateTime? updatedAt,
  }) {
    return LibraryEntry(
      item: item,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
