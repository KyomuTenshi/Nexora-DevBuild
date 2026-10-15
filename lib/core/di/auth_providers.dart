import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/repositories/in_memory_auth_repository.dart';
import 'package:nexora/domain/entities/app_user.dart';
import 'package:nexora/domain/repositories/auth_repository.dart';

/// По умолчанию авторизация «в памяти» (тесты). Настоящий Firebase
/// подставляется в main() через overrides.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = InMemoryAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Текущий пользователь как поток: null, если не вошёл.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});