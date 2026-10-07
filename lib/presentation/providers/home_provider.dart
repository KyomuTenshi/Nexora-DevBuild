import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/home_feed.dart';

/// FutureProvider сам хранит состояние «загрузка / данные / ошибка».
final homeFeedProvider = FutureProvider<HomeFeed>((ref) {
  final repository = ref.watch(mediaRepositoryProvider);
  return repository.getHomeFeed();
});