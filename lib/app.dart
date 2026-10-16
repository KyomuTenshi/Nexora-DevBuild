import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/cloud_sync_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/push_provider.dart';
import 'presentation/providers/shake_discover_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/widgets/achievement_toast.dart';
import 'presentation/widgets/root_messenger.dart';

class NexoraApp extends ConsumerWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final accent = ref.watch(profileProvider.select((p) => p.accent));

    // Держим включёнными синхронизацию с облаком, push и «встряхни»,
    // пока работает приложение
    ref.watch(cloudSyncProvider);
    ref.watch(pushProvider);
    ref.watch(shakeDiscoverProvider);

    return MaterialApp.router(
      title: 'Nexora',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootMessengerKey,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: themeMode,
      // Язык: системные элементы (даты, кнопки, подсказки) тоже переключаются
      locale: Locale(language.name),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Всеми переходами управляет GoRouter
      routerConfig: ref.watch(routerProvider),
      // Плашка «Достижение получено» поверх любого экрана
      builder: (context, child) =>
          AchievementToastHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
