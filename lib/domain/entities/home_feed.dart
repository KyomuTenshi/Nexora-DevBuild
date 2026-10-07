import 'media_item.dart';

/// Слайд верхней карусели.
class FeaturedBanner {
  const FeaturedBanner({
    required this.item,
    required this.badge,
    required this.caption,
  });

  final MediaItem item;
  final String badge; // «Новый сезон»
  final String caption; // «Сезон 2 · Action · Fantasy»
}

/// Данные главного экрана, которые приходят с сервера.
/// «Продолжить просмотр/чтение» собираются из библиотеки пользователя.
class HomeFeed {
  const HomeFeed({required this.featured, required this.popular});

  final List<FeaturedBanner> featured;
  final List<MediaItem> popular;
}
