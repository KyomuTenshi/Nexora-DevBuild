import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexora/domain/entities/app_user.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/domain/repositories/auth_repository.dart';

/// Настоящая авторизация через Firebase Authentication (почта и пароль).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  AppUser? _map(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final trimmed = name?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        await credential.user?.updateDisplayName(trimmed);
        await credential.user?.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw _convert(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Переводит коды Firebase в типы приложения, чтобы остальной код
  /// не зависел от строк Firebase.
  AuthException _convert(FirebaseAuthException e) {
    final failure = switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'user-disabled' => AuthFailure.invalidCredentials,
      'invalid-email' => AuthFailure.invalidEmail,
      'email-already-in-use' => AuthFailure.emailInUse,
      'weak-password' => AuthFailure.weakPassword,
      'too-many-requests' => AuthFailure.tooManyRequests,
      'network-request-failed' => AuthFailure.network,
      _ => AuthFailure.unknown,
    };
    return AuthException(failure, e.code);
  }
}
