import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:nexora/domain/entities/push_message.dart';
import 'package:nexora/domain/repositories/push_repository.dart';

/// Настоящие push-уведомления через Firebase Cloud Messaging.
///
/// Про устаревшие методы: в firebase_messaging 17 getToken() и onTokenRefresh
/// помечены deprecated в пользу register() и onRegistered. Но новые методы
/// выдают не FCM-токен, а Firebase Installation ID (адрес для «прямой отправки»).
/// Консоль Firebase (тестовое сообщение) работает с FCM-токеном, поэтому
/// пока используем проверенные методы и заглушаем предупреждение точечно.
class FirebasePushRepository implements PushRepository {
  FirebasePushRepository(this._messaging, this._db);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    try {
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } catch (e) {
      // Например, на эмуляторе без сервисов Google Play
      debugPrint('FCM: токен недоступен ($e)');
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> onTokenRefresh() => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> onForegroundMessage() =>
      FirebaseMessaging.onMessage.map(_convert);

  @override
  Stream<PushMessage> onMessageOpened() =>
      FirebaseMessaging.onMessageOpenedApp.map(_convert);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _convert(message);
  }

  @override
  Future<void> saveToken({required String uid, required String token}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .set({
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  PushMessage _convert(RemoteMessage message) {
    final data = {
      for (final entry in message.data.entries) entry.key: '${entry.value}',
    };
    return PushMessage(
      title: message.notification?.title ?? data['title'] ?? 'Nexora',
      body: message.notification?.body ?? data['body'] ?? '',
      data: data,
    );
  }
}