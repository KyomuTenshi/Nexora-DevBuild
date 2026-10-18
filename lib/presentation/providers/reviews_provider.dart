import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/presentation/providers/profile_provider.dart';

class Review {
  const Review({
    required this.author,
    required this.rating,
    required this.text,
    required this.ago,
    this.mine = false,
  });

  final String author;

  /// От 0 до 5. 0 значит «без оценки».
  final int rating;
  final String text;
  final String ago;
  final bool mine;
}

/// Отзывы по id тайтла. Пока без сервера: показываем только свои отзывы,
/// новые встают сверху.
class ReviewsNotifier extends Notifier<Map<int, List<Review>>> {
  @override
  Map<int, List<Review>> build() => const {};

  List<Review> of(int itemId) => state[itemId] ?? const [];

  /// Добавить отзыв. За отзыв начисляем 50 очков (как в магазине оформления).
  void add(int itemId, Review review) {
    state = {
      ...state,
      itemId: [review, ...of(itemId)],
    };
    ref.read(profileProvider.notifier).earn(50);
  }
}

final reviewsProvider =
    NotifierProvider<ReviewsNotifier, Map<int, List<Review>>>(
      ReviewsNotifier.new,
    );
