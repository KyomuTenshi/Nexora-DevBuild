import '../entities/push_message.dart';

/// Контракт push-уведомлений: что умеем, но не чем (FCM, Firebase).
abstract class PushRepository {
  /// Спрашивает разрешение на уведомления. true, если разрешили.
  Future<bool> requestPermission();

  /// Токен этого устройства или null (например, нет сервисов Google Play).
  Future<String?> getToken();

  /// Токен меняется время от времени, об этом сообщает поток.
  Stream<String> onTokenRefresh();

  /// Сообщение пришло, пока приложение открыто.
  Stream<PushMessage> onForegroundMessage();

  /// Пользователь нажал на уведомление, приложение было в фоне.
  Stream<PushMessage> onMessageOpened();

  /// Уведомление, по нажатию на которое приложение запустилось с нуля.
  Future<PushMessage?> getInitialMessage();

  /// Запоминает токен устройства за аккаунтом, чтобы сообщения можно
  /// было отправлять конкретному человеку.
  Future<void> saveToken({required String uid, required String token});
}
