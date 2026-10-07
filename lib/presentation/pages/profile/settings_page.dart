import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/presentation/pages/profile/profile_edit_page.dart';
import 'package:nexora/presentation/pages/profile/store_page.dart';
import 'package:nexora/presentation/providers/onboarding_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/theme_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeProvider);
    final accent = ref.watch(profileProvider.select((p) => p.accentIndex));

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const _SectionTitle('Внешний вид'),
          _Block(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Тема',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Тёмная'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Светлая'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto_outlined),
                          label: Text('Авто'),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (v) =>
                          ref.read(themeProvider.notifier).setMode(v.first),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Цвет приложения',
                    style: TextStyle(fontWeight: FontWeight.w700),
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
          const _SectionTitle('Профиль'),
          _Block(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Редактировать профиль'),
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
                  title: const Text('Оформление и магазин'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StorePage()),
                  ),
                ),
              ],
            ),
          ),
          const _SectionTitle('Данные'),
          _Block(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.waving_hand_outlined),
                  title: const Text('Показать приветствие снова'),
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
                    'Сбросить профиль и очки',
                    style: TextStyle(color: scheme.error),
                  ),
                  onTap: () => _confirmReset(context, ref),
                ),
              ],
            ),
          ),
          const _SectionTitle('О приложении'),
          const _Block(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('Nexora'),
                  subtitle: Text('Версия 1.0.0 · учебный проект'),
                ),
                Divider(indent: 56),
                ListTile(
                  leading: Icon(Icons.code_rounded),
                  title: Text('Разработчик'),
                  subtitle: Text('Piperite Games'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сбросить профиль?'),
        content: const Text(
          'Имя, оформление, очки и уровень вернутся к начальным значениям. '
          'Библиотека не изменится.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      ref.read(profileProvider.notifier).edit((_) => ProfileState.initial());
      showInfo(context, 'Профиль сброшен');
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
