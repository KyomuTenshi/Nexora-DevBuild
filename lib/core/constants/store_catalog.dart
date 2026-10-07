import 'package:flutter/material.dart';

enum StoreCategory { banner, frame, badge }

/// Предмет оформления профиля: фон, рамка аватара или значок.
class StoreItem {
  const StoreItem({
    required this.id,
    required this.category,
    required this.title,
    required this.price,
    this.colors = const [],
  });

  final String id;
  final StoreCategory category;
  final String title;

  /// Цена в очках. 0 значит «бесплатно».
  final int price;

  /// Для фона: два цвета градиента. Для рамки: первый цвет рамки.
  final List<Color> colors;
}

const kBannerBase = 'banner_base';
const kFrameGold = 'frame_gold';
const kBadgeFan = 'badge_fan';

const List<StoreItem> kStoreItems = [
  // Фоны профиля
  StoreItem(
    id: kBannerBase, category: StoreCategory.banner, title: 'Базовый',
    price: 0, colors: [Color(0xFF4B3A9E), Color(0xFF14111F)],
  ),
  StoreItem(
    id: 'banner_sakura', category: StoreCategory.banner, title: 'Сакура',
    price: 0, colors: [Color(0xFFE8648A), Color(0xFF3A1730)],
  ),
  StoreItem(
    id: 'banner_night', category: StoreCategory.banner, title: 'Ночной Токио',
    price: 300, colors: [Color(0xFF2B1F6B), Color(0xFF0B0A24)],
  ),
  StoreItem(
    id: 'banner_forest', category: StoreCategory.banner, title: 'Лес духов',
    price: 500, colors: [Color(0xFF1F9460), Color(0xFF07241A)],
  ),
  StoreItem(
    id: 'banner_sunset', category: StoreCategory.banner, title: 'Закат',
    price: 400, colors: [Color(0xFFFFB347), Color(0xFF4A1D3B)],
  ),
  StoreItem(
    id: 'banner_ocean', category: StoreCategory.banner, title: 'Океан',
    price: 350, colors: [Color(0xFF3AA0F5), Color(0xFF08203F)],
  ),

  // Рамки аватара
  StoreItem(
    id: 'frame_none', category: StoreCategory.frame, title: 'Без рамки',
    price: 0, colors: [Colors.transparent],
  ),
  StoreItem(
    id: kFrameGold, category: StoreCategory.frame, title: 'Золото',
    price: 0, colors: [Color(0xFFFFC53D)],
  ),
  StoreItem(
    id: 'frame_violet', category: StoreCategory.frame, title: 'Аметист',
    price: 200, colors: [Color(0xFFB59CFF)],
  ),
  StoreItem(
    id: 'frame_pink', category: StoreCategory.frame, title: 'Сакура',
    price: 250, colors: [Color(0xFFFF7FA5)],
  ),
  StoreItem(
    id: 'frame_cyan', category: StoreCategory.frame, title: 'Неон',
    price: 400, colors: [Color(0xFF2CE6D6)],
  ),

  // Значки (подпись под именем)
  StoreItem(
    id: kBadgeFan, category: StoreCategory.badge, title: 'Anime Fan', price: 0,
  ),
  StoreItem(
    id: 'badge_otaku', category: StoreCategory.badge, title: 'Otaku',
    price: 150,
  ),
  StoreItem(
    id: 'badge_reader', category: StoreCategory.badge, title: 'Book Worm',
    price: 150,
  ),
  StoreItem(
    id: 'badge_sensei', category: StoreCategory.badge, title: 'Sensei',
    price: 500,
  ),
];

/// Что открыто у нового пользователя.
const Set<String> kInitiallyUnlocked = {
  kBannerBase, 'banner_sakura', 'frame_none', kFrameGold, kBadgeFan,
};

StoreItem storeItemById(String id) =>
    kStoreItems.firstWhere((e) => e.id == id, orElse: () => kStoreItems.first);

List<StoreItem> storeItemsOf(StoreCategory category) =>
    kStoreItems.where((e) => e.category == category).toList();
