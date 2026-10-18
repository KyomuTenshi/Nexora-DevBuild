import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexora/data/repositories/firebase_auth_repository.dart';
import 'package:nexora/domain/entities/app_user.dart';
import 'package:nexora/domain/errors/app_exception.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  late MockFirebaseAuth auth;
  late FirebaseAuthRepository repo;

  setUp(() {
    auth = MockFirebaseAuth();
    repo = FirebaseAuthRepository(auth);
  });

  MockUser fakeUser({String? email = 'a@b.com', String? name}) {
    final user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn(email);
    when(() => user.displayName).thenReturn(name);
    return user;
  }

  group('пользователь', () {
    test('без входа currentUser равен null', () {
      when(() => auth.currentUser).thenReturn(null);

      expect(repo.currentUser, isNull);
    });

    test('поля Firebase превращаются в AppUser', () {
      // Пользователя создаём ДО when: вложенные when в mocktail запрещены
      final firebaseUser = fakeUser(name: 'Олжас');
      when(() => auth.currentUser).thenReturn(firebaseUser);

      final user = repo.currentUser!;

      expect(user.uid, 'u1');
      expect(user.email, 'a@b.com');
      expect(user.shownName, 'Олжас');
    });

    test('если почты нет, будет пустая строка', () {
      final firebaseUser = fakeUser(email: null);
      when(() => auth.currentUser).thenReturn(firebaseUser);

      expect(repo.currentUser!.email, '');
    });

    test('поток состояний тоже превращается в AppUser', () {
      final firebaseUser = fakeUser();
      when(() => auth.authStateChanges())
          .thenAnswer((_) => Stream<User?>.fromIterable([firebaseUser, null]));

      expect(
        repo.authStateChanges(),
        emitsInOrder([
          isA<AppUser>().having((u) => u.uid, 'uid', 'u1'),
          isNull,
          emitsDone,
        ]),
      );
    });
  });

  group('вход', () {
    test('почта обрезается от пробелов, пароль уходит как есть', () async {
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => MockUserCredential());

      await repo.signIn(email: '  a@b.com ', password: ' secret1 ');

      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'a@b.com',
          password: ' secret1 ',
        ),
      ).called(1);
    });

    // Какой код Firebase во что превращается
    const codes = <String, AuthFailure>{
      'invalid-credential': AuthFailure.invalidCredentials,
      'wrong-password': AuthFailure.invalidCredentials,
      'user-not-found': AuthFailure.invalidCredentials,
      'user-disabled': AuthFailure.invalidCredentials,
      'invalid-email': AuthFailure.invalidEmail,
      'email-already-in-use': AuthFailure.emailInUse,
      'weak-password': AuthFailure.weakPassword,
      'too-many-requests': AuthFailure.tooManyRequests,
      'network-request-failed': AuthFailure.network,
      'что-то-новое': AuthFailure.unknown,
    };

    for (final entry in codes.entries) {
      test('код ${entry.key} даёт ${entry.value.name}', () async {
        when(
          () => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: entry.key));

        await expectLater(
          repo.signIn(email: 'a@b.com', password: 'secret1'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.failure,
              'failure',
              entry.value,
            ),
          ),
        );
      });
    }
  });

  group('регистрация', () {
    late MockUser created;

    setUp(() {
      created = MockUser();
      final credential = MockUserCredential();
      when(() => credential.user).thenReturn(created);
      when(() => created.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => created.reload()).thenAnswer((_) async {});
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);
    });

    test('имя обрезается, сохраняется и профиль перезагружается', () async {
      await repo.register(
        email: ' a@b.com ',
        password: 'secret1',
        name: '  Олжас ',
      );

      verify(
        () => auth.createUserWithEmailAndPassword(
          email: 'a@b.com',
          password: 'secret1',
        ),
      ).called(1);
      verify(() => created.updateDisplayName('Олжас')).called(1);
      verify(() => created.reload()).called(1);
    });

    test('без имени профиль не трогаем', () async {
      await repo.register(email: 'a@b.com', password: 'secret1');
      await repo.register(email: 'a@b.com', password: 'secret1', name: '   ');

      verifyNever(() => created.updateDisplayName(any()));
      verifyNever(() => created.reload());
    });

    test('занятая почта даёт emailInUse', () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await expectLater(
        repo.register(email: 'a@b.com', password: 'secret1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.emailInUse,
          ),
        ),
      );
    });
  });

  test('выход передаётся в Firebase', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});

    await repo.signOut();

    verify(() => auth.signOut()).called(1);
  });
}
