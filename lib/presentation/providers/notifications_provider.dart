import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  List<NotificationItem> build() => const [];

  /// Новое уведомление из push: встаёт первым и считается непрочитанным.
  void addIncoming({required String title, required String message}) {
    final item = NotificationItem(
      id: 'push-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      timeAgo: 'Только что',
      icon: Icons.notifications_active_rounded,
    );
    state = [item, ...state];
  }

  void markRead(String id) {
    state = [for (final n in state) n.id == id ? n.copyWith(isRead: true) : n];
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
