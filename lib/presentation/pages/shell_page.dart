import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora/presentation/providers/language_provider.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';

/// Каркас с навигацией. Телефон: нижняя панель. Планшет и широкое окно:
/// боковая панель NavigationRail. Сами вкладки приходят из GoRouter.
class ShellPage extends ConsumerWidget {
  const ShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Ширина, с которой нижнюю панель заменяет боковая.
  static const double _railBreakpoint = 600;

  /// Ширина, с которой боковая панель показывает подписи рядом с иконками.
  static const double _extendedBreakpoint = 1000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = navigationShell.currentIndex;
    final unread = ref.watch(unreadCountProvider);
    final s = ref.watch(stringsProvider);
    final width = MediaQuery.sizeOf(context).width;

    void select(int i) => ref.read(shellTabProvider.notifier).setTab(i);

    final items = <({IconData icon, IconData selected, String label})>[
      (
        icon: Icons.home_outlined,
        selected: Icons.home_rounded,
        label: s.navHome,
      ),
      (
        icon: Icons.desktop_windows_outlined,
        selected: Icons.desktop_windows_rounded,
        label: s.navCatalog,
      ),
      (
        icon: Icons.menu_book_outlined,
        selected: Icons.menu_book_rounded,
        label: s.navLibrary,
      ),
      (
        icon: Icons.notifications_none_rounded,
        selected: Icons.notifications_rounded,
        label: s.navNotifications,
      ),
      (
        icon: Icons.menu_rounded,
        selected: Icons.menu_rounded,
        label: s.navMenu,
      ),
    ];

    // Значок уведомлений (индекс 3) получает счётчик непрочитанных
    Widget iconFor(int i, IconData data) {
      final icon = Icon(data);
      if (i != 3) return icon;
      return Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: icon,
      );
    }

    final useRail = width >= _railBreakpoint;

    // Кнопка «Назад» с любой вкладки возвращает на Главную, а не закрывает приложение
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) select(0);
      },
      child: Scaffold(
        body: useRail
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: index,
                    onDestinationSelected: select,
                    extended: width >= _extendedBreakpoint,
                    labelType: width >= _extendedBreakpoint
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    destinations: [
                      for (var i = 0; i < items.length; i++)
                        NavigationRailDestination(
                          icon: iconFor(i, items[i].icon),
                          selectedIcon: iconFor(i, items[i].selected),
                          label: Text(items[i].label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: navigationShell),
                ],
              )
            : navigationShell,
        bottomNavigationBar: useRail
            ? null
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: select,
                destinations: [
                  for (var i = 0; i < items.length; i++)
                    NavigationDestination(
                      icon: iconFor(i, items[i].icon),
                      selectedIcon: iconFor(i, items[i].selected),
                      label: items[i].label,
                    ),
                ],
              ),
      ),
    );
  }
}
