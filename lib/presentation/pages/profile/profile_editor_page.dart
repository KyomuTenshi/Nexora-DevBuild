import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/showcase.dart';
import 'package:nexora/presentation/pages/profile/profile_edit_page.dart';
import 'package:nexora/presentation/pages/profile/profile_info_page.dart';
import 'package:nexora/presentation/pages/profile/profile_privacy_page.dart';
import 'package:nexora/presentation/pages/profile/showcases_editor_page.dart';
import 'package:nexora/presentation/pages/profile/store_page.dart';
import 'package:nexora/presentation/providers/profile_layout_provider.dart';

void _push(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

/// Редактор профиля: разделы, как в Steam (Основное, Информация, Оформление,
/// Витрины, Приватность). Каждый раздел сохраняется на своей странице.
class ProfileEditorPage extends ConsumerWidget {
  const ProfileEditorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ownedCount =
    ref.watch(profileLayoutProvider.select((l) => l.owned.length));

    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование профиля')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _Row(
                  icon: Icons.person_outline_rounded,
                  title: 'Основное и фото',
                  subtitle: 'Имя, о себе, жанры, свои аватар и фон',
                  onTap: () => _push(context, const ProfileEditPage()),
                ),
                const Divider(height: 1, indent: 56),
                _Row(
                  icon: Icons.badge_outlined,
                  title: 'Информация',
                  subtitle: 'Настоящее имя, город, статус',
                  onTap: () => _push(context, const ProfileInfoPage()),
                ),
                const Divider(height: 1, indent: 56),
                _Row(
                  icon: Icons.palette_outlined,
                  title: 'Рамка, фон и значок',
                  subtitle: 'Оформление из магазина очков',
                  onTap: () => _push(context, const StorePage()),
                ),
                const Divider(height: 1, indent: 56),
                _Row(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Витрины',
                  subtitle:
                  'Открыто $ownedCount из ${ShowcaseType.values.length}',
                  onTap: () => _push(context, const ShowcasesEditorPage()),
                ),
                const Divider(height: 1, indent: 56),
                _Row(
                  icon: Icons.lock_outline_rounded,
                  title: 'Приватность',
                  subtitle: 'Что видно на странице профиля',
                  onTap: () => _push(context, const ProfilePrivacyPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}