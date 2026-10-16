import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/auth_providers.dart';
import 'package:nexora/data/repositories/in_memory_auth_repository.dart';
import 'package:nexora/domain/errors/app_exception.dart';
import 'package:nexora/presentation/pages/auth/login_page.dart';

void main() {
  group('InMemoryAuthRepository', () {
    test(
      'регистрация входит в аккаунт, выход сбрасывает пользователя',
      () async {
        final repo = InMemoryAuthRepository();
        addTearDown(repo.dispose);

        expect(repo.currentUser, isNull);

        await repo.register(
          email: 'User@Example.com',
          password: 'secret1',
          name: 'Тест',
        );
        expect(repo.currentUser?.email, 'user@example.com');
        expect(repo.currentUser?.shownName, 'Тест');

        await repo.signOut();
        expect(repo.currentUser, isNull);
      },
    );

    test('неверный пароль даёт invalidCredentials', () async {
      final repo = InMemoryAuthRepository();
      addTearDown(repo.dispose);
      await repo.register(email: 'a@b.com', password: 'secret1');
      await repo.signOut();

      expect(
        () => repo.signIn(email: 'a@b.com', password: 'wrong-pass'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.invalidCredentials,
          ),
        ),
      );
    });

    test('повторная регистрация той же почты даёт emailInUse', () async {
      final repo = InMemoryAuthRepository();
      addTearDown(repo.dispose);
      await repo.register(email: 'a@b.com', password: 'secret1');

      expect(
        () => repo.register(email: 'a@b.com', password: 'secret1'),
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

  group('LoginPage', () {
    Future<void> pumpLogin(WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginPage())),
      );
    }

    testWidgets('пустая форма показывает ошибки проверки', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Войти').last);
      await tester.pump();

      expect(
        find.text('Введите почту, например name@mail.com'),
        findsOneWidget,
      );
      expect(find.text('Минимум 6 символов'), findsOneWidget);
    });

    testWidgets('неверные данные показывают понятную ошибку', (tester) async {
      await pumpLogin(tester);

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'nobody@mail.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
      await tester.tap(find.text('Войти').last);
      await tester.pumpAndSettle();

      expect(find.text('Неверная почта или пароль'), findsOneWidget);
    });

    testWidgets('регистрация создаёт пользователя в репозитории', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
      await tester.pump();
      expect(find.text('Создать аккаунт'), findsOneWidget);

      // Поля: имя, почта, пароль
      await tester.enterText(find.byType(TextFormField).at(0), 'Тест');
      await tester.enterText(find.byType(TextFormField).at(1), 'me@mail.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
      await tester.tap(find.text('Создать аккаунт'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(LoginPage)),
      );
      expect(
        container.read(authRepositoryProvider).currentUser?.email,
        'me@mail.com',
      );
    });
  });
}
