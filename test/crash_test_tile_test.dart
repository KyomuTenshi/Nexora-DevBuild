import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/core/di/crash_providers.dart';
import 'package:nexora/data/crash/fake_crash_reporter.dart';
import 'package:nexora/presentation/widgets/crash_test_tile.dart';

Future<FakeCrashReporter> pumpTile(WidgetTester tester) async {
  final reporter = FakeCrashReporter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [crashReporterProvider.overrideWithValue(reporter)],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: CrashTestTile())),
      ),
    ),
  );
  return reporter;
}

void main() {
  testWidgets('тестовая ошибка уходит в отчёт, приложение не падает', (
    tester,
  ) async {
    final reporter = await pumpTile(tester);

    await tester.tap(find.text('Тестовая ошибка (Crashlytics)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(reporter.errors, hasLength(1));
    expect(reporter.crashes, 0);
    expect(find.textContaining('Отчёт отправлен'), findsOneWidget);
  });

  testWidgets('тестовое падение требует подтверждения', (tester) async {
    final reporter = await pumpTile(tester);

    await tester.tap(find.text('Тестовое падение'));
    await tester.pumpAndSettle();
    expect(find.text('Уронить приложение?'), findsOneWidget);
    expect(reporter.crashes, 0);

    await tester.tap(find.text('Уронить'));
    await tester.pumpAndSettle();
    expect(reporter.crashes, 1);
  });

  testWidgets('отмена не роняет приложение', (tester) async {
    final reporter = await pumpTile(tester);

    await tester.tap(find.text('Тестовое падение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(reporter.crashes, 0);
    expect(find.text('Уронить приложение?'), findsNothing);
  });
}
