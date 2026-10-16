import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/data/push/fake_push_repository.dart';
import 'package:nexora/domain/repositories/push_repository.dart';

/// По умолчанию push «в памяти» (тесты). Настоящий FCM подставляется в main().
final pushRepositoryProvider = Provider<PushRepository>((ref) {
  final repo = FakePushRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
