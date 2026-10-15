import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/presentation/pages/demo/state_demo_page.dart';

/// Достаёт текст счётчика по префиксу ключа: setstate / inherited / provider.
String _countOf(WidgetTester tester, String prefix) =>
    tester.widget<Text>(find.byKey(Key('$prefix-count'))).data!;

/// Нажимает «+» у нужного счётчика (сперва прокручивает к нему).
Future<void> _add(WidgetTester tester, String prefix) async {
  final button = find.byKey(Key('$prefix-add'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('каждый счётчик растёт независимо от остальных', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StateDemoPage()));

    await _add(tester, 'setstate');
    await _add(tester, 'provider');
    await _add(tester, 'provider');

    expect(_countOf(tester, 'setstate'), 'Серий просмотрено: 1');
    expect(_countOf(tester, 'inherited'), 'Серий просмотрено: 0');
    expect(_countOf(tester, 'provider'), 'Серий просмотрено: 2');

    await _add(tester, 'inherited');
    expect(_countOf(tester, 'inherited'), 'Серий просмотрено: 1');
  });
}