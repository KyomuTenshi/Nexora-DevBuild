import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora/presentation/widgets/skeleton.dart';

void main() {
  testWidgets('скелетон рисуется и анимируется без ошибок', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SkeletonShimmer(child: SkeletonBox(width: 100, height: 20)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SkeletonBox), findsOneWidget);
  });

  testWidgets('при «уменьшить движение» блик отключён', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: SkeletonShimmer(child: SkeletonBox(width: 100, height: 20)),
          ),
        ),
      ),
    );

    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(SkeletonBox), findsOneWidget);
  });
}