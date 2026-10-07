import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/onboarding/onboarding_page.dart';
import 'presentation/pages/shell_page.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/widgets/achievement_toast.dart';

class NexoraApp extends ConsumerWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final accent = ref.watch(profileProvider.select((p) => p.accent));

    return MaterialApp(
      title: 'Nexora',
      debugShowCheckedModeBanner: false,
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
      // Плашка «Достижение получено» поверх любого экрана
      builder: (context, child) =>
          AchievementToastHost(child: child ?? const SizedBox.shrink()),
      home: const _StartGate(),
    );
  }
}

/// Решает, что показать при запуске: приветствие или приложение.
/// Переключение живёт внутри маршрута, поэтому срабатывает сразу при complete().
class _StartGate extends ConsumerWidget {
  const _StartGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(onboardedProvider);
    return onboarded ? const ShellPage() : const OnboardingPage();
  }
}