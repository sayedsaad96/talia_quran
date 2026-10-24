import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';
import 'package:talia_quran/core/accessibility/clarity_mode.dart';
import 'package:talia_quran/features/quran/presentation/widgets/app_quran_page_content.dart';
import 'package:talia_quran/features/quran/presentation/widgets/mushaf_zoomable_page.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_page_font_guard.dart';

void main() {
  qcf.QuranPage pageFor(int pageNumber) {
    final pages = GetPage()..getQuran(604);
    return pages.staticPages[pageNumber - 1];
  }

  testWidgets('uses one canonical model id for the guarded QCF leaf', (
    tester,
  ) async {
    final page = pageFor(2);
    final controller = PageController();
    addTearDown(controller.dispose);
    final highlights = <qcf.HighlightVerse>[];
    const style = TextStyle(fontSize: 19);

    await tester.pumpWidget(
      MaterialApp(
        home: AppQuranPageContent(
          page: page,
          pageController: controller,
          highlights: highlights,
          isDarkMode: true,
          isTajweed: false,
          ayahStyle: style,
          basmallahBuilder: structuralBasmallahBuilder(null),
        ),
      ),
    );

    final guard = tester.widget<QuranPageFontGuard>(
      find.byType(QuranPageFontGuard),
    );
    final repaint = guard.child as RepaintBoundary;
    final scale = repaint.child as SystemTextScale;
    final zoom = scale.child as MushafZoomablePage;
    final quranPage = zoom.child as qcf.QuranSinglePageWidget;

    expect(guard.pageNumber, page.pageNumber);
    expect(quranPage.key, ValueKey('page_content_${page.pageNumber}'));
    expect(quranPage.pageIndex, page.pageNumber);
    expect(quranPage.page, same(page));
    expect(quranPage.highlights, same(highlights));
    expect(quranPage.pageController, same(controller));
    expect(quranPage.isTajweed, isFalse);
    expect(quranPage.isDark, isTrue);
    expect(quranPage.ayahStyle, same(style));
  });

  testWidgets('uses a finite local MediaQuery for a spread pane', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Size? paneSize;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1280, 800)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: 640,
              height: 760,
              child: QuranPagePaneViewport(
                child: Builder(
                  builder: (context) {
                    paneSize = MediaQuery.sizeOf(context);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(paneSize, const Size(640, 760));
  });
}
