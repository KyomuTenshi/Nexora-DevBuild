import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/pages/auth/login_page.dart';
import 'package:nexora/presentation/pages/catalog/catalog_page.dart';
import 'package:nexora/presentation/pages/demo/state_demo_page.dart';
import 'package:nexora/presentation/pages/detail/detail_page.dart';
import 'package:nexora/presentation/pages/home/home_page.dart';
import 'package:nexora/presentation/pages/library/library_page.dart';
import 'package:nexora/presentation/pages/menu/menu_page.dart';
import 'package:nexora/presentation/pages/notifications/notifications_page.dart';
import 'package:nexora/presentation/pages/onboarding/onboarding_page.dart';
import 'package:nexora/presentation/pages/player/watch_page.dart';
import 'package:nexora/presentation/pages/profile/achievements_page.dart';
import 'package:nexora/presentation/pages/profile/favorites_page.dart';
import 'package:nexora/presentation/pages/profile/profile_screen.dart';
import 'package:nexora/presentation/pages/profile/settings_page.dart';
import 'package:nexora/presentation/pages/profile/store_page.dart';
import 'package:nexora/presentation/pages/reader/reader_page.dart';
import 'package:nexora/presentation/pages/shell_page.dart';
import 'package:nexora/presentation/providers/onboarding_provider.dart';

/// Имена маршрутов. Переходим по имени (context.pushNamed), а не по строке пути:
/// если путь изменится, менять код вызова не придётся.
abstract final class AppRoute {
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const home = 'home';
  static const catalog = 'catalog';
  static const library = 'library';
  static const notifications = 'notifications';
  static const menu = 'menu';
  static const detail = 'detail';
  static const watch = 'watch';
  static const read = 'read';
  static const profile = 'profile';
  static const favorites = 'favorites';
  static const achievements = 'achievements';
  static const store = 'store';
  static const settings = 'settings';
  static const stateDemo = 'stateDemo';
}

/// Пути вкладок нижнего меню в том же порядке, что и кнопки.
const List<String> kTabPaths = [
  '/home',
  '/catalog',
  '/library',
  '/notifications',
  '/menu',
];

/// Маршруты, куда пускаем только вошедших пользователей.
const Set<String> kProtectedPaths = {'/profile'};

/// Роутер лежит в провайдере: так он получает доступ к состоянию приложения
/// (для redirect) и его можно подменить в тестах.
final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter сам не следит за Riverpod. Этот счётчик говорит ему:
  // «приветствие или вход изменились, пересчитай redirect».
  final refresh = ValueNotifier<int>(0);
  void bump(Object? previous, Object? next) => refresh.value++;
  ref.listen<bool>(onboardedProvider, bump);
  ref.listen(authStateProvider, bump);

  final router = GoRouter(
    initialLocation: kTabPaths.first,
    refreshListenable: refresh,
    // Защита маршрутов:
    // 1) без приветствия в приложение не попасть;
    // 2) защищённые экраны требуют входа и после входа возвращают обратно.
    redirect: (context, state) {
      final location = state.matchedLocation;

      final onboarded = ref.read(onboardedProvider);
      if (!onboarded) return location == '/onboarding' ? null : '/onboarding';
      if (location == '/onboarding') return kTabPaths.first;

      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null && kProtectedPaths.contains(location)) {
        return '/login?from=${Uri.encodeComponent(location)}';
      }
      if (user != null && location == '/login') {
        final from = state.uri.queryParameters['from'];
        return from != null && from.startsWith('/') ? from : kTabPaths.first;
      }
      return null;
    },
    errorBuilder: (context, state) =>
    const _NotFoundPage(message: 'Такой страницы нет'),
    routes: [
      GoRoute(
        path: '/onboarding',
        name: AppRoute.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login,
        builder: (context, state) => const LoginPage(),
      ),

      // Вложенная навигация: нижнее меню + у каждой вкладки свой стек
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: AppRoute.home,
              builder: (context, state) => const HomePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/catalog',
              name: AppRoute.catalog,
              builder: (context, state) => const CatalogPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/library',
              name: AppRoute.library,
              builder: (context, state) => const LibraryPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/notifications',
              name: AppRoute.notifications,
              builder: (context, state) => const NotificationsPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/menu',
              name: AppRoute.menu,
              builder: (context, state) => const MenuPage(),
            ),
          ]),
        ],
      ),

      // Страница тайтла с параметром :id. Сам тайтл передаётся через extra,
      // поэтому после перезапуска по голой ссылке он не найдётся (см. README).
      GoRoute(
        path: '/title/:id',
        name: AppRoute.detail,
        builder: (context, state) {
          final item = state.extra;
          if (item is! MediaItem) {
            return const _NotFoundPage(message: 'Тайтл не найден');
          }
          return DetailPage(item: item);
        },
        routes: [
          GoRoute(
            path: 'watch/:episode',
            name: AppRoute.watch,
            pageBuilder: (context, state) {
              final item = state.extra;
              final episode =
              int.tryParse(state.pathParameters['episode'] ?? '');
              return MaterialPage<void>(
                key: state.pageKey,
                // Плеер открывается снизу, как отдельный экран
                fullscreenDialog: true,
                child: item is MediaItem && episode != null
                    ? WatchPage(item: item, episode: episode)
                    : const _NotFoundPage(message: 'Серия не найдена'),
              );
            },
          ),
          GoRoute(
            path: 'read/:chapter',
            name: AppRoute.read,
            pageBuilder: (context, state) {
              final item = state.extra;
              final chapter =
              int.tryParse(state.pathParameters['chapter'] ?? '');
              return MaterialPage<void>(
                key: state.pageKey,
                child: item is MediaItem && chapter != null
                    ? ReaderPage(item: item, chapter: chapter)
                    : const _NotFoundPage(message: 'Глава не найдена'),
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: '/profile',
        name: AppRoute.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/favorites',
        name: AppRoute.favorites,
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/achievements',
        name: AppRoute.achievements,
        builder: (context, state) => const AchievementsPage(),
      ),
      GoRoute(
        path: '/store',
        name: AppRoute.store,
        builder: (context, state) => const StorePage(),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      // Учебное демо недели 3: setState → InheritedWidget → provider
      GoRoute(
        path: '/demo/state',
        name: AppRoute.stateDemo,
        builder: (context, state) => const StateDemoPage(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Заглушка: неизвестный адрес или не хватает данных для экрана.
class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 56),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.goNamed(AppRoute.home),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}