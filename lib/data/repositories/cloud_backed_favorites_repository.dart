import 'package:nexora/data/cloud/push_quietly.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/repositories/cloud_sync_repository.dart';
import 'package:nexora/domain/repositories/favorites_repository.dart';

/// Избранное: читает с диска, пишет на диск и (если вошёл) в облако.
/// Это паттерн «Декоратор»: обёртка с тем же интерфейсом, поэтому
/// остальное приложение ничего не знает про облако.
class CloudBackedFavoritesRepository implements FavoritesRepository {
  CloudBackedFavoritesRepository({
    required this.local,
    required this.cloud,
    required this.currentUid,
  });

  final FavoritesRepository local;
  final CloudSyncRepository cloud;

  /// uid вошедшего пользователя или null.
  final String? Function() currentUid;

  @override
  List<MediaItem> getAll() => local.getAll();

  @override
  Future<void> add(MediaItem item) async {
    await local.add(item);
    final uid = currentUid();
    if (uid != null) pushQuietly(() => cloud.saveFavorite(uid, item));
  }

  @override
  Future<void> remove(int itemId) async {
    await local.remove(itemId);
    final uid = currentUid();
    if (uid != null) pushQuietly(() => cloud.removeFavorite(uid, itemId));
  }
}
