import '../entities/app_user.dart';

/// Контракт авторизации. Ошибки приходят как AuthException.
abstract class AuthRepository {
  /// Текущий пользователь или null, если не вошёл.
  AppUser? get currentUser;

  /// Поток изменений: вход, выход, смена аккаунта.
  Stream<AppUser?> authStateChanges();

  Future<void> signIn({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    String? name,
  });

  Future<void> signOut();
}
