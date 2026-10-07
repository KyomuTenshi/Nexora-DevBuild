import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/l10n/app_strings.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/presentation/pages/profile/profile_edit_page.dart';
import 'package:nexora/presentation/pages/profile/store_page.dart';
import 'package:nexora/presentation/providers/language_provider.dart';
import 'package:nexora/presentation/providers/onboarding_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/theme_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final s = ref.watch(stringsProvider);
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeProvider);
    final accent = ref.watch(profileProvider.select((p) => p.accentIndex));

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
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < AppColors.accents.length; i++)
                        Tooltip(
                          message: AppColors.accentNames[i],
                          child: GestureDetector(
                            onTap: () => ref
                                .read(profileProvider.notifier)
                                .edit((p) => p.copyWith(accentIndex: i)),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accents[i],
                                border: Border.all(
                                  color: i == accent
                                      ? scheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: i == accent
                                  ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 20)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _SectionTitle(s.profileSection),
          _Block(
            child: Column(
              children: [
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
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StorePage()),
                  ),
                ),
              ],
            ),
          ),
          _SectionTitle(s.dataSection),
          _Block(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.waving_hand_outlined),
                  title: Text(s.showWelcome),
                  onTap: () {
                    ref.read(onboardedProvider.notifier).reset();
                    // Возвращаемся к корню: там теперь приветствие
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                ),
                const Divider(indent: 56),
                ListTile(
                  leading: Icon(Icons.restart_alt_rounded, color: scheme.error),
                  title: Text(
                    s.resetProfile,
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () => _confirmReset(context, ref),
                ),
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
        ],
      ),
    );
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
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}