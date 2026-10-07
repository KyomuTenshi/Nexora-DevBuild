import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/pages/profile/profile_screen.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/widgets/profile_widgets.dart';

/// Маленький аватар пользователя. Показывает своё фото или инициалы,
/// по нажатию открывает профиль.
class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Semantics(
      button: true,
      label: 'Профиль',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openProfile(context),
        // Без рамки внутренний круг на 4 меньше, поэтому добавляем 4
        child: ProfileAvatar(
          text: profile.avatarText,
          frameId: 'frame_none',
          imagePath: profile.avatarPath,
          adjust: profile.avatarAdjust,
          size: size + 4,
        ),
      ),
    );
  }
}