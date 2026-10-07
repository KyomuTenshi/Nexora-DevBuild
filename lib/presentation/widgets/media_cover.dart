import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/presentation/providers/cover_provider.dart';
import 'package:nexora/presentation/widgets/cover_art.dart';

/// Обложка тайтла: настоящая картинка, а пока она грузится или недоступна,
/// красивый градиент. Если у тайтла нет ссылки, пробуем найти её через API.
class MediaCover extends ConsumerWidget {
  const MediaCover({super.key, required this.item, this.child});

  final MediaItem item;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = item.imageUrl ?? ref.watch(coverUrlProvider(item)).value;
    return CoverArt(seed: item.id, imageUrl: url, child: child);
  }
}