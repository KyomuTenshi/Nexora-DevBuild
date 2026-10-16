/// Поток «телефон встряхнули». Сколько и когда, решает реализация.
abstract interface class ShakeRepository {
  Stream<void> get shakes;
}
