import 'dart:async';

import 'package:nexora/domain/entities/app_user.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/auth_repository.dart';

/// Авторизация «в памяти»: без сети и Firebase. Используется по умолчанию
/// и в тестах. Пользователи живут, пока работает приложение.
class InMemoryAuthRepository implements AuthRepository {
  final Map<String, ({String password, String? name})> _accounts = {};
  final StreamController<AppUser?> _controller =
  StreamController<AppUser?>.broadcast();
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authStateChanges() {
    late final StreamController<AppUser?> controller;
    StreamSubscription<AppUser?>? subscription;
    controller = StreamController<AppUser?>(
      onListen: () {
        controller.add(_current);
        subscription = _controller.stream.listen(controller.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null || account.password != password) {
      throw const AuthException(AuthFailure.invalidCredentials);
    }
    _set(AppUser(uid: key, email: key, displayName: account.name));
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException(AuthFailure.emailInUse);
    }
    if (password.length < 6) {
      throw const AuthException(AuthFailure.weakPassword);
    }
    _accounts[key] = (password: password, name: name);
    _set(AppUser(uid: key, email: key, displayName: name));
  }

  @override
  Future<void> signOut() async => _set(null);

  void _set(AppUser? user) {
    _current = user;
    _controller.add(user);
  }

  void dispose() => _controller.close();
}