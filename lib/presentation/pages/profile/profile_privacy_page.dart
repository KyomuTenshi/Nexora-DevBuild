import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/showcase.dart';
import 'package:nexora/presentation/providers/profile_layout_provider.dart';

/// Что показывать на странице своего профиля. Переключатели сохраняются сразу.
class ProfilePrivacyPage extends ConsumerWidget {
  const ProfilePrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final layout = ref.watch(profileLayoutProvider);
    final notifier = ref.read(profileLayoutProvider.notifier);

    Widget tile(
        String title,
        String subtitle,
        bool value,
        ProfileLayout Function(ProfileLayout l, bool v) change,
        ) {
      return SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (v) => notifier.edit((l) => change(l, v)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Приватность')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                tile(
                  'Настоящее имя',
                  'Под вашим ником',
                  layout.showRealName,
                      (l, v) => l.copyWith(showRealName: v),
                ),
                tile(
                  'Город или страна',
                  'Рядом с настоящим именем',
                  layout.showLocation,
                      (l, v) => l.copyWith(showLocation: v),
                ),
                tile(
                  'Статус',
                  'Короткая фраза о себе',
                  layout.showStatus,
                      (l, v) => l.copyWith(showStatus: v),
                ),
                tile(
                  'Уровень и опыт',
                  'Полоса опыта на странице',
                  layout.showLevel,
                      (l, v) => l.copyWith(showLevel: v),
                ),
                tile(
                  'Что я смотрю сейчас',
                  'Строка «В сети · смотрит…»',
                  layout.showPresence,
                      (l, v) => l.copyWith(showPresence: v),
                ),
                tile(
                  'Разделы',
                  'Аниме, Манга, Избранное, Списки, Отзывы',
                  layout.showSections,
                      (l, v) => l.copyWith(showSections: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Витрины (${ShowcaseType.values.length} шт.) скрываются и показываются '
                'в разделе «Витрины».',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}