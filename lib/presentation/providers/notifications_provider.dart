import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/mock/mock_data.dart';
import 'package:nexora/domain/entities/media_item.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    this.item,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;

  /// Тайтл, к которому относится уведомление (по тапу откроем его страницу).
  final MediaItem? item;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        message: message,
        timeAgo: timeAgo,
        icon: icon,
        item: item,
        isRead: isRead ?? this.isRead,
      );
}

class NotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() => const [
        NotificationItem(
          id: '1',
          title: 'Новая серия!',
          message: 'Вышла 1143 серия аниме «One Piece».',
          timeAgo: '10 мин назад',
          icon: Icons.play_circle_fill_rounded,
          item: MockData.onePiece,
        ),
        NotificationItem(
          id: '2',
          title: 'Обновление в библиотеке',
          message: 'Добавлена новая глава 377 манги «Berserk».',
          timeAgo: '2 часа назад',
          icon: Icons.menu_book_rounded,
          item: MockData.berserk,
        ),
        NotificationItem(
          id: '3',
          title: 'Новинка сезона',
          message: 'Премьера «Solo Leveling» Сезон 2 уже в каталоге!',
          timeAgo: 'Вчера',
          icon: Icons.stars_rounded,
          item: MockData.soloLeveling,
          isRead: true,
        ),
        NotificationItem(
          id: '4',
          title: 'Награда получена',
          message: '+100 очков за достижение «Марафонец».',
          timeAgo: '2 дня назад',
          icon: Icons.emoji_events_rounded,
          isRead: true,
        ),
      ];

  void markRead(String id) {
    state = [
      for (final n in state) n.id == id ? n.copyWith(isRead: true) : n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clear() => state = const [];
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);

/// Число непрочитанных для значка на иконке колокольчика.
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).where((n) => !n.isRead).length;
});
