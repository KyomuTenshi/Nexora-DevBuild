import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/presentation/providers/home_provider.dart';
import 'package:nexora/presentation/providers/similar_provider.dart';
import 'package:nexora/presentation/widgets/profile_avatar_button.dart';
import 'package:nexora/presentation/widgets/search_box.dart';

class HomeTopBar extends ConsumerWidget {
  const HomeTopBar({super.key});

  /// То же, что жест «потянуть вниз»: сбрасываем кэш и грузим заново.
  void _refresh(WidgetRef ref) {
    ref.read(mediaRepositoryProvider).clearCache();
    ref.invalidate(recommendedProvider);
    ref.invalidate(homeFeedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Поиск работает прямо здесь: выпадающая панель с подсказками
          const Expanded(child: SearchBox()),
          PopupMenuButton<String>(
            tooltip: 'Ещё',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (value) {
              if (value == 'refresh') _refresh(ref);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Обновить страницу'),
                  ],
                ),
              ),
            ],
          ),
          // Аватар открывает профиль отдельной страницей
          const ProfileAvatarButton(size: 40),
        ],
      ),
    );
  }
}