/// Контракт хранилища оценок пользователя: id тайтла -> от 1 до 5.
abstract class RatingsRepository {
  Map<int, int> getAll();
  Future<void> set(int itemId, int value);
  Future<void> remove(int itemId);
}