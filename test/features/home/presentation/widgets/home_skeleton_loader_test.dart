import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/skeleton_loader.dart';

void main() {
  testWidgets('HomeSkeletonLoader golden baseline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeSkeletonLoader()),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(HomeSkeletonLoader),
      matchesGoldenFile('goldens/home_skeleton_loader.png'),
    );
  });
}
