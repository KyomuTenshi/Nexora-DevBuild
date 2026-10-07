import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/domain/entities/media_item.dart';

/// Ссылка на обложку для тайтла, у которого её нет (демо-записи библиотеки).
/// Запрос уходит только когда карточка реально появилась на экране.
final coverUrlProvider =
FutureProvider.family<String?, MediaItem>((ref, item) {
  return ref.watch(mediaRepositoryProvider).findCoverUrl(item);
});