import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true, когда последний ответ взят из сохранённых данных (нет сети).
/// По нему экраны показывают сообщение «Используются сохранённые данные».
class CacheStatusNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    if (state != value) state = value;
  }
}

final cacheStatusProvider = NotifierProvider<CacheStatusNotifier, bool>(
  CacheStatusNotifier.new,
);