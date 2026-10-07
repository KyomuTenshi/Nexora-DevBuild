import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/widgets/empty_view.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/profile_avatar_button.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final items = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read') notifier.markAllRead();
                if (value == 'clear') notifier.clear();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'read', child: Text('Прочитать все')),
                PopupMenuItem(value: 'clear', child: Text('Очистить все')),
              ],
            ),
          const ProfileAvatarButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? const EmptyView(
        icon: Icons.notifications_off_outlined,
        title: 'Уведомлений нет',
        message: 'Здесь будут новости о новых сериях и главах.',
      )
          : ListView.builder(
        // Нижний отступ, чтобы последний пункт не прятался под панелью
        padding: EdgeInsets.only(
          top: 8,
          bottom: 8 + MediaQuery.paddingOf(context).bottom,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final n = items[i];
          // Свайп влево удаляет уведомление
          return Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: scheme.error.withValues(alpha: 0.85),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.white),
            ),
            onDismissed: (_) {
              notifier.remove(n.id);
              showInfo(context, 'Уведомление удалено');
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: n.isRead
                    ? scheme.surfaceContainerHighest
                    : scheme.primary.withValues(alpha: 0.2),
                child: Icon(
                  n.icon,
                  color:
                  n.isRead ? scheme.onSurfaceVariant : scheme.primary,
                ),
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(n.message),
                  const SizedBox(height: 4),
                  Text(
                    n.timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: n.isRead
                  ? null
                  : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                ),
              ),
              onTap: () {
                notifier.markRead(n.id);
                final item = n.item;
                if (item != null) openDetail(context, item);
              },
            ),
          );
        },
      ),
    );
  }
}