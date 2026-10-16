import 'dart:async';

import 'package:flutter/foundation.dart';

/// Отправляет данные в облако и не ждёт результата. Ошибка не ломает
/// приложение: локальная запись уже сделана, а синхронизация догонит позже.
void pushQuietly(Future<void> Function() action) {
  unawaited(
    action().then<void>(
          (_) {},
      onError: (Object error) => debugPrint('Облако: не отправлено ($error)'),
    ),
  );
}