/// Почему не удалось определить местоположение.
enum LocationProblem {
  /// Геолокация выключена на телефоне.
  servicesOff,

  /// Пользователь не дал разрешение.
  denied,

  /// Разрешение запрещено насовсем: менять можно только в настройках телефона.
  deniedForever,

  /// Разрешение есть, но позицию определить не получилось (нет сигнала, таймаут).
  unavailable,
}

class LocationException implements Exception {
  const LocationException(this.problem);

  final LocationProblem problem;

  @override
  String toString() => 'LocationException: ${problem.name}';
}