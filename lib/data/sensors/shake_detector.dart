/// Превращает поток «силы ускорения» в события встряски.
///
/// Встряска — значение не меньше [threshold] (м/с²). После неё
/// [cooldown] новые не считаем, иначе одно движение дало бы десяток событий.
/// Время берётся через [now], чтобы в тестах не ждать по-настоящему.
Stream<void> detectShakes(
  Stream<double> magnitudes, {
  double threshold = 15,
  Duration cooldown = const Duration(seconds: 1),
  DateTime Function() now = DateTime.now,
}) {
  DateTime? last;
  return magnitudes
      .where((magnitude) {
        if (magnitude < threshold) return false;
        final time = now();
        final prev = last;
        if (prev != null && time.difference(prev) < cooldown) return false;
        last = time;
        return true;
      })
      .map((_) {});
}
