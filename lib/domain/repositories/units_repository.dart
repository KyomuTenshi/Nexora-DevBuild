import 'package:nexora/domain/entities/media_item.dart';
import 'package:nexora/domain/entities/media_unit.dart';

/// Откуда приложение берёт списки серий (аниме) и глав (манга).
abstract interface class UnitsRepository {
  /// Страница списка, нумерация страниц с нуля, по [kUnitsPageSize] записей.
  /// Если данных о тайтле нет, возвращает пустую страницу.
  Future<UnitsPage> getUnits(MediaItem item, {required int page});
}
