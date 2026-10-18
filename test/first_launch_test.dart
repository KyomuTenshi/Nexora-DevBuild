import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/presentation/providers/notifications_provider.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';
import 'package:nexora/presentation/providers/reviews_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// При самом первом запуске в приложении нет чужих данных: ни уведомлений,
/// ни отзывов, ни очков.
void main() {
  Future<ProviderContainer> freshStart() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('уведомлений нет', () async {
    final container = await freshStart();

    expect(container.read(notificationsProvider), isEmpty);
    expect(container.read(unreadCountProvider), 0);
  });

  test('отзывов нет', () async {
    final container = await freshStart();

    expect(container.read(reviewsProvider.notifier).of(1), isEmpty);
  });

  test('профиль гостя: без имени, фото, очков и опыта', () async {
    final container = await freshStart();
    final profile = container.read(profileProvider);

    expect(profile.displayName, 'Гость');
    expect(profile.avatarText, isEmpty);
    expect(profile.avatarPath, isEmpty);
    expect(profile.bannerPath, isEmpty);
    expect(profile.points, 0);
    expect(profile.xp, 0);
    expect(profile.level, 1);
    expect(profile.pinned, isEmpty);
  });
}
