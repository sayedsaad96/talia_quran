import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:talia_quran/benchmarks/quran_profile_recorder.dart';
import 'package:talia_quran/benchmarks/quran_spread_profile.dart';
import 'package:talia_quran/core/accessibility/clarity_mode.dart';
import 'package:talia_quran/features/quran/presentation/widgets/mushaf_zoomable_page.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_page_font_guard.dart';

void main() {
  testWidgets('turn boundary waits for a fresh frame timestamp', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final before = SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final boundary = quranProfileFrameBoundary();
    await tester.pump(const Duration(milliseconds: 20));
    expect(await boundary, greaterThan(before.inMicroseconds));
  });

  testWidgets('real spread panes retain canonical IDs across resize', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: QuranSpreadProfile(
          config: QuranProfileConfig.parse('spread'),
          automate: false,
        ),
      ),
    );

    void checkPanes(double width, double height) {
      final guards = find.byType(QuranPageFontGuard);
      for (final page in [1, 2]) {
        final finder = find.byWidgetPredicate(
          (w) => w is QuranPageFontGuard && w.pageNumber == page,
        );
        final guard = tester.widget<QuranPageFontGuard>(finder);
        final context = tester.element(finder);
        expect(MediaQuery.sizeOf(context), Size(width / 2, height));
        final repaint = guard.child as RepaintBoundary;
        final scale = repaint.child as SystemTextScale;
        final zoom = scale.child as MushafZoomablePage;
        final leaf = zoom.child as qcf.QuranSinglePageWidget;
        expect(leaf.page.pageNumber, page);
        expect(leaf.pageIndex, page);
        expect(leaf.highlights.any((h) => h.page == page), isTrue);
      }
      expect(guards, findsAtLeastNWidgets(2));
      final right = find.byWidgetPredicate(
        (w) => w is QuranPageFontGuard && w.pageNumber == 1,
      );
      final left = find.byWidgetPredicate(
        (w) => w is QuranPageFontGuard && w.pageNumber == 2,
      );
      expect(
        tester.getCenter(right).dx,
        greaterThan(tester.getCenter(left).dx),
      );
    }

    checkPanes(1280, 800);
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    await tester.pump();
    checkPanes(1000, 700);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
