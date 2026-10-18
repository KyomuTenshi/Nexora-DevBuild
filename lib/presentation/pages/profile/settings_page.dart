import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexora/core/l10n/app_strings.dart';
import 'package:nexora/core/router/app_router.dart';
import 'package:nexora/presentation/pages/profile/profile_edit_page.dart';
import 'package:nexora/presentation/providers/dev_mode_provider.dart';
import 'package:nexora/presentation/providers/language_provider.dart';
import 'package:nexora/presentation/providers/onboarding_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/theme_provider.dart';
import 'package:nexora/presentation/widgets/accent_picker.dart';
import 'package:nexora/presentation/widgets/account_tile.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/push_tile.dart';
import 'package:nexora/presentation/widgets/device_tiles.dart';
import 'package:nexora/presentation/widgets/crash_test_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final s = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeProvider);
    final accent = ref.watch(profileProvider.select((p) => p.accentIndex));
    final devMode = ref.watch(devModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _SectionTitle(s.appearance),
          _Block(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.theme,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(s.themeDark),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(s.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_outlined),
                          label: Text(s.themeAuto),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (v) =>
                          ref.read(themeProvider.notifier).setMode(v.first),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.languageTitle,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<AppLanguage>(
                      showSelectedIcon: false,
                      segments: [
                        for (final l in AppLanguage.values)
                          ButtonSegment(
                            value: l,
                            icon: const Icon(Icons.language_rounded),
                            label: Text(l.label),
                          ),
                      ],
                      selected: {language},
                      onSelectionChanged: (v) =>
                          ref.read(languageProvider.notifier).set(v.first),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.accentColor,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  AccentPicker(
                    selectedIndex: accent,
                    onSelected: (i) => ref
                        .read(profileProvider.notifier)
                        .edit((p) => p.copyWith(accentIndex: i)),
                  ),
                ],
              ),
            ),
          ),
          _SectionTitle(s.profileSection),
          _Block(
            child: Column(
              children: [
                // Аккаунт Firebase: вход, имя с почтой и кнопка «Выйти»
                const AccountTile(),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(s.editProfile),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileEditPage(),
                    ),
                  ),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(s.storeAndStyle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.pushNamed(AppRoute.store),
                ),
              ],
            ),
          ),
          _SectionTitle(s.dataSection),
          _Block(
            child: Column(
              children: [
                PushTile(showToken: devMode),
                const Divider(indent: 56),
                const DeviceStatusTile(),
                const Divider(indent: 56),
                const ShakeTile(),
              ],
            ),
          ),
          _SectionTitle(s.aboutSection),
          _Block(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Nexora'),
                  subtitle: Text(s.versionLine),
                  // Семь нажатий открывают служебный раздел
                  onTap: () => _tapVersion(context, ref),
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: const Icon(Icons.code_rounded),
                  title: Text(s.developer),
                  subtitle: const Text('Piperite Games'),
                ),
              ],
            ),
          ),
          if (devMode) ...[
            const _SectionTitle('Для разработчика'),
            _Block(
              child: Column(
                children: [
                  const CrashTestTile(),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('Демо: способы управления состоянием'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.pushNamed(AppRoute.stateDemo),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.waving_hand_outlined),
                    title: Text(s.showWelcome),
                    // Достаточно сбросить флаг: redirect в GoRouter сам
                    // перенаправит на экран приветствия
                    onTap: () => ref.read(onboardedProvider.notifier).reset(),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: Icon(
                      Icons.restart_alt_rounded,
                      color: scheme.error,
                    ),
                    title: Text(
                      s.resetProfile,
                      style: TextStyle(color: scheme.error),
                    ),
                    onTap: () => _confirmReset(context, ref),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Icons.visibility_off_outlined),
                    title: const Text('Скрыть раздел'),
                    onTap: () => ref.read(devModeProvider.notifier).disable(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _tapVersion(BuildContext context, WidgetRef ref) {
    final left = ref.read(devModeProvider.notifier).tapVersion();
    if (left == 0) {
      showInfo(context, 'Раздел для разработчика открыт');
    } else if (left <= 3) {
      showInfo(context, 'Раздел для разработчика через нажатий: $left');
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.resetTitle),
        content: Text(s.resetText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.reset),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ref.read(profileProvider.notifier).edit((_) => ProfileState.initial());
      showInfo(context, s.profileWasReset);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
