import 'package:flutter/material.dart';
import 'package:nexora/domain/entities/library_entry.dart';
import 'package:nexora/domain/entities/media_item.dart';

extension LibraryStatusLabel on LibraryStatus {
  /// «Смотрю» для аниме и «Читаю» для манги.
  String labelFor(MediaType type) {
    final anime = type == MediaType.anime;
    return switch (this) {
      LibraryStatus.inProgress => anime ? 'Смотрю' : 'Читаю',
      LibraryStatus.paused => 'На паузе',
      LibraryStatus.completed => anime ? 'Просмотрено' : 'Прочитано',
      LibraryStatus.planned => 'В планах',
      LibraryStatus.dropped => 'Брошено',
    };
  }

  IconData get icon => switch (this) {
        LibraryStatus.inProgress => Icons.play_circle_outline_rounded,
        LibraryStatus.paused => Icons.pause_circle_outline_rounded,
        LibraryStatus.completed => Icons.check_circle_outline_rounded,
        LibraryStatus.planned => Icons.schedule_rounded,
        LibraryStatus.dropped => Icons.cancel_outlined,
      };
}
