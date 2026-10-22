import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/domain/services/quran_spread_policy.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_spread_view.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('keeps the right page physically right in $direction text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final builtPages = <int>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: direction,
          child: SizedBox.expand(
            child: QuranSpreadView(
              spread: const QuranSpread(rightPage: 1, leftPage: 2),
              pageBuilder: (page) {
                builtPages.add(page);
                return SizedBox(key: ValueKey('page_$page'));
              },
            ),
          ),
        ),
      );

      expect(builtPages, [2, 1]);
      expect(
        tester.getCenter(find.byKey(const ValueKey('page_1'))).dx,
        greaterThan(tester.getCenter(find.byKey(const ValueKey('page_2'))).dx),
      );
      expect(tester.getSize(find.byKey(const ValueKey('page_1'))).width, 640);
      expect(tester.getSize(find.byKey(const ValueKey('page_2'))).width, 640);
    });
  }

  testWidgets('keeps a missing left page out of the right half', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final builtPages = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox.expand(
          child: QuranSpreadView(
            spread: const QuranSpread(rightPage: 1, leftPage: null),
            pageBuilder: (page) {
              builtPages.add(page);
              return SizedBox(key: ValueKey('page_$page'));
            },
          ),
        ),
      ),
    );

    final rightPage = find.byKey(const ValueKey('page_1'));
    expect(builtPages, [1]);
    expect(tester.getCenter(rightPage).dx, greaterThan(640));
    expect(tester.getSize(rightPage).width, 640);
  });

  testWidgets('keeps a missing right page out of the left half', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final builtPages = <int>[];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox.expand(
          child: QuranSpreadView(
            spread: const QuranSpread(rightPage: null, leftPage: 2),
            pageBuilder: (page) {
              builtPages.add(page);
              return SizedBox(key: ValueKey('page_$page'));
            },
          ),
        ),
      ),
    );

    final leftPage = find.byKey(const ValueKey('page_2'));
    expect(builtPages, [2]);
    expect(tester.getCenter(leftPage).dx, lessThan(640));
    expect(tester.getSize(leftPage).width, 640);
  });
}
