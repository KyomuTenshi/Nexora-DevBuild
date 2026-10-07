import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/pages/profile/settings_page.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final avatarText = ref.watch(profileProvider.select((p) => p.avatarText));
    final unread = ref.watch(unreadCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                // Тап по строке поиска открывает каталог и сразу ставит курсор
                onTap: () {
                  ref.read(shellTabProvider.notifier).setTab(1);
                  ref.read(searchFocusProvider.notifier).request();
                },
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Найти аниме или мангу',
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const Icon(Icons.search_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Badge(
              isLabelVisible: unread > 0,
              smallSize: 8,
              child: const Icon(Icons.more_vert_rounded),
            ),
            onSelected: (value) {
              switch (value) {
                case 'notifications':
                  ref.read(shellTabProvider.notifier).setTab(3);
                case 'library':
                  ref.read(shellTabProvider.notifier).setTab(2);
                case 'settings':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'notifications',
                child: Text(unread > 0 ? 'Уведомления ($unread)' : 'Уведомления'),
              ),
              const PopupMenuItem(value: 'library', child: Text('Моя библиотека')),
              const PopupMenuItem(value: 'settings', child: Text('Настройки')),
            ],
          ),
          // Аватар ведёт в профиль
          GestureDetector(
            onTap: () => ref.read(shellTabProvider.notifier).setTab(4),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                avatarText,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
