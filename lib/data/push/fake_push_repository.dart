import 'dart:async';

import 'package:nexora/domain/entities/push_message.dart';
import 'package:nexora/domain/repositories/push_repository.dart';

/// Push «в памяти»: по умолчанию и в тестах, без Firebase и телефона.
class FakePushRepository implements PushRepository {
  FakePushRepository({this.granted = true, this.token = 'fake-token'});

  final bool granted;
  final String? token;

  /// Что приложение запомнило за аккаунтами (для проверок в тестах).
  final List<({String uid, String token})> savedTokens = [];

  PushMessage? initialMessage;

  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();
  final _refresh = StreamController<String>.broadcast();

  void emitForeground(PushMessage message) => _foreground.add(message);
  void emitOpened(PushMessage message) => _opened.add(message);
  void emitTokenRefresh(String value) => _refresh.add(value);

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<String?> getToken() async => granted ? token : null;

  @override
  Stream<String> onTokenRefresh() => _refresh.stream;

  @override
  Stream<PushMessage> onForegroundMessage() => _foreground.stream;

  @override
  Stream<PushMessage> onMessageOpened() => _opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<void> saveToken({required String uid, required String token}) async {
    savedTokens.add((uid: uid, token: token));
  }

  void dispose() {
    _foreground.close();
    _opened.close();
    _refresh.close();
  }
}
