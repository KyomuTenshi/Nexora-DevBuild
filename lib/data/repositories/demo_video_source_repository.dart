import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/video_source.dart';
import 'package:nexora/domain/repositories/video_source_repository.dart';

/// Демо-источник видео. Права на показ настоящих аниме у приложения нет,
/// поэтому вместо серий играют короткие мультфильмы Blender Foundation
/// (свободная лицензия CC BY). Чтобы подключить настоящие серии, нужно
/// заменить этот класс другой реализацией [VideoSourceRepository].
class DemoVideoSourceRepository implements VideoSourceRepository {
  const DemoVideoSourceRepository();

  static const _base =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample';

  static const _clips = [
    ('BigBuckBunny.mp4', 'Big Buck Bunny'),
    ('Sintel.mp4', 'Sintel'),
    ('ElephantsDream.mp4', 'Elephants Dream'),
    ('TearsOfSteel.mp4', 'Tears of Steel'),
  ];

  @override
  Future<VideoSource> getSource(MediaItem item, int episode) async {
    final (file, name) = _clips[(item.id + episode) % _clips.length];
    return VideoSource(
      url: Uri.parse('$_base/$file'),
      credit: 'Демо-ролик «$name», Blender Foundation, CC BY',
    );
  }
}
