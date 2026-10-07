import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/catalog_filters.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/widgets/media_labels.dart';
import 'package:nexora/presentation/widgets/profile_widgets.dart';

/// Настройки профиля: имя, инициалы, о себе, цвет интерфейса, жанры, витрины.
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _avatar;
  late final TextEditingController _bio;
  late int _accent;
  late Set<String> _genres;
  late bool _showFavorites;
  late bool _showAchievements;
  late bool _showStats;

  bool _avatarTouched = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    _name = TextEditingController(text: p.name);
    _avatar = TextEditingController(text: p.avatarText);
    _bio = TextEditingController(text: p.bio);
    _accent = p.accentIndex;
    _genres = {...p.genres};
    _showFavorites = p.showFavorites;
    _showAchievements = p.showAchievements;
    _showStats = p.showStats;
  }

  @override
  void dispose() {
    _name.dispose();
    _avatar.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() {
      _nameError = null;
      // Пока инициалы не правили вручную, считаем их из имени
      if (!_avatarTouched) _avatar.text = initialsOf(value);
    });
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Введите имя');
      return;
    }
    final avatar = _avatar.text.trim().isEmpty
        ? initialsOf(name)
        : _avatar.text.trim().toUpperCase();

    ref.read(profileProvider.notifier).edit(
          (p) => p.copyWith(
            name: name,
            avatarText: avatar,
            bio: _bio.text.trim(),
            accentIndex: _accent,
            genres: _genres.toList(),
            showFavorites: _showFavorites,
            showAchievements: _showAchievements,
            showStats: _showStats,
          ),
        );
    Navigator.of(context).pop();
    showInfo(context, 'Профиль сохранён');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: ProfileAvatar(
              text: _avatar.text.isEmpty ? '?' : _avatar.text.toUpperCase(),
              frameId: profile.frameId,
              level: profile.level,
              size: 112,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            onChanged: _onNameChanged,
            decoration: InputDecoration(
              labelText: 'Имя',
              errorText: _nameError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _avatar,
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() => _avatarTouched = true),
            decoration: const InputDecoration(
              labelText: 'Инициалы на аватаре',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bio,
            maxLength: 80,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'О себе',
              hintText: 'Например: люблю сёнэн и ночные марафоны',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const _Title('Цвет приложения'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              for (var i = 0; i < AppColors.accents.length; i++)
                Tooltip(
                  message: AppColors.accentNames[i],
                  child: GestureDetector(
                    onTap: () => setState(() => _accent = i),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accents[i],
                        border: Border.all(
                          color: i == _accent
                              ? scheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: i == _accent
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _Title('Любимые жанры'),
          const SizedBox(height: 4),
          Text(
            'По ним мы подбираем раздел «Для вас» на главной.',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in kGenres)
                FilterChip(
                  label: Text(g),
                  selected: _genres.contains(g),
                  onSelected: (v) => setState(() {
                    if (v) {
                      _genres.add(g);
                    } else {
                      _genres.remove(g);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const _Title('Что показывать в профиле'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Статистику'),
            value: _showStats,
            onChanged: (v) => setState(() => _showStats = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Любимое аниме'),
            value: _showFavorites,
            onChanged: (v) => setState(() => _showFavorites = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Достижения'),
            value: _showAchievements,
            onChanged: (v) => setState(() => _showAchievements = v),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
  }
}
