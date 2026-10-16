import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:nexora/firebase_options.dart';

/// Обработчик сообщений, когда приложение закрыто или в фоне.
/// Он обязан быть функцией верхнего уровня: Android запускает его
/// в отдельном изолированном процессе, где состояния приложения нет.
/// Уведомления с заголовком и текстом система показывает сама,
/// а здесь можно обработать «тихие» сообщения с одними данными.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM в фоне: ${message.messageId}');
}
