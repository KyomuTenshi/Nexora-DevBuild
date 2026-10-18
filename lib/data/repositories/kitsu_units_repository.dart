import 'package:nexora/core/constants/api_constants.dart';
import 'package:nexora/data/api/api_client.dart';
import 'package:nexora/data/dto/kitsu_dto.dart';
import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_unit.dart';
import 'package:nexora/domain/repositories/units_repository.dart';

/// Серии и главы из Kitsu: /anime/{id}/episodes и /manga/{id}/chapters.
class KitsuUnitsRepository implements UnitsRepository {
  KitsuUnitsRepository(this._client);

  final ApiClient _client;

  @override
  Future<UnitsPage> getUnits(MediaItem item, {required int page}) async {
    final kitsuId = _kitsuId(item);
    if (kitsuId == null) return const UnitsPage(items: [], total: 0);

    final isManga = item.type == MediaType.manga;
    final path = isManga
        ? '/manga/$kitsuId/chapters'
        : '/anime/$kitsuId/episodes';
    final params = {'page[limit]': '$kUnitsPageSize', 'sort': 'number'};
    // Первая страница уходит без offset: адрес запроса не меняется,
    // и сохранённый на диске ответ подходит
    if (page > 0) params['page[offset]'] = '${page * kUnitsPageSize}';

    return parseKitsuUnits(await _client.getJson(path, params));
  }

  /// Тайтлы из демо-данных (не из Kitsu) списка серий не имеют.
  int? _kitsuId(MediaItem item) {
    final offset = item.type == MediaType.manga
        ? kKitsuMangaIdOffset
        : kKitsuAnimeIdOffset;
    final id = item.id - offset;
    return id > 0 && id < kMangaIdOffset ? id : null;
  }
}
