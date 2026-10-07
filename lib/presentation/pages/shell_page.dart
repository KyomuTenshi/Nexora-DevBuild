import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/language_provider.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/providers/shell_provider.dart';
import 'catalog/catalog_page.dart';
import 'home/home_page.dart';
import 'library/library_page.dart';
import 'menu/menu_page.dart';
import 'notifications/notifications_page.dart';

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  static const _pages = <Widget>[
    HomePage(),
    CatalogPage(),
    LibraryPage(),
    NotificationsPage(),
    MenuPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabProvider);
    final unread = ref.watch(unreadCountProvider);
    final s = ref.watch(stringsProvider);

    // Кнопка «Назад» с любой вкладки возвращает на Главную, а не закрывает приложение
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(shellTabProvider.notifier).setTab(0);
      },
      child: Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(shellTabProvider.notifier).setTab(i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: s.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.desktop_windows_outlined),
              selectedIcon: const Icon(Icons.desktop_windows_rounded),
              label: s.navCatalog,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded),
              label: s.navLibrary,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: s.navNotifications,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_rounded),
              selectedIcon: const Icon(Icons.menu_rounded),
              label: s.navMenu,
            ),
          ],
        ),
      ),
    );
  }
}