import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/catalog_filters.dart';
import 'package:nexora/core/theme/app_colors.dart';
import 'package:nexora/presentation/providers/onboarding_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

/// Приветствие при первом запуске: 3 шага. После него открывается Главная.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _steps = 3;

  final _controller = PageController();
  final _name = TextEditingController();
  final Set<String> _genres = {};
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _steps - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish(saveAnswers: true);
    }
  }

  void _finish({required bool saveAnswers}) {
    if (saveAnswers) {
      final name = _name.text.trim();
      ref.read(profileProvider.notifier).edit(
            (p) => p.copyWith(
              name: name.isEmpty ? null : name,
              avatarText: name.isEmpty ? null : initialsOf(name),
              genres: _genres.toList(),
            ),
          );
    }
    // После этого NexoraApp сам заменит приветствие на Главную
    ref.read(onboardedProvider.notifier).complete();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentIndex = ref.watch(profileProvider.select((p) => p.accentIndex));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _finish(saveAnswers: false),
                child: const Text('Пропустить'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomeStep(accent: scheme.primary),
                  _NameStep(
                    controller: _name,
                    accentIndex: accentIndex,
                    onAccent: (i) => ref
                        .read(profileProvider.notifier)
                        .edit((p) => p.copyWith(accentIndex: i)),
                  ),
                  _GenresStep(
                    selected: _genres,
                    onToggle: (g, v) => setState(() {
                      if (v) {
                        _genres.add(g);
                      } else {
                        _genres.remove(g);
                      }
                    }),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  for (var i = 0; i < _steps; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == _page
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(130, 50),
                    ),
                    child: Text(_page == _steps - 1 ? 'Начать' : 'Далее'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget feature(IconData icon, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, AppColors.pink],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 54,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nexora',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Аниме и манга в одном приложении',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          feature(Icons.play_circle_outline_rounded, 'Смотрите',
              'Продолжайте с того места, где остановились'),
          feature(Icons.menu_book_outlined, 'Читайте',
              'Манга с удобной читалкой и закладками'),
          feature(Icons.emoji_events_outlined, 'Получайте награды',
              'Очки, уровни и оформление профиля'),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
    required this.accentIndex,
    required this.onAccent,
  });

  final TextEditingController controller;
  final int accentIndex;
  final ValueChanged<int> onAccent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Как вас зовут?',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Имя увидите только вы. Его можно изменить в профиле.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Имя',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Выберите цвет',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              for (var i = 0; i < AppColors.accents.length; i++)
                GestureDetector(
                  onTap: () => onAccent(i),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accents[i],
                      border: Border.all(
                        color: i == accentIndex
                            ? scheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: i == accentIndex
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenresStep extends StatelessWidget {
  const _GenresStep({required this.selected, required this.onToggle});

  final Set<String> selected;
  final void Function(String genre, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Что вам нравится?',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите жанры, и мы подберём тайтлы на главной.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in kGenres)
                FilterChip(
                  label: Text(g),
                  selected: selected.contains(g),
                  onSelected: (v) => onToggle(g, v),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
