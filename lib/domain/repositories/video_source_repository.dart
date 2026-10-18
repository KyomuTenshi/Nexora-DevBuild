import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/video_source.dart';

/// Откуда приложение берёт видео серий. Плееру всё равно, откуда адрес:
/// своё хранилище, лицензированный каталог или демо-ролики.
abstract interface class VideoSourceRepository {
  Future<VideoSource> getSource(MediaItem item, int episode);
}
