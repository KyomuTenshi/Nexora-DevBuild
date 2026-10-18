/// Откуда играть серию: адрес видео и подпись автора (если нужна по лицензии).
class VideoSource {
  const VideoSource({required this.url, this.credit});

  final Uri url;
  final String? credit;
}
