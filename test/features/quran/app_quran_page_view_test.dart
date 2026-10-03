import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/widgets/quran_page/quran_repository.dart'
    as qcf_repository;
import 'package:talia_quran/features/quran/domain/services/quran_page_order_policy.dart';
import 'package:talia_quran/features/quran/presentation/widgets/app_quran_page_view.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_page_font_guard.dart';

void main() {
  testWidgets(
    'structural basmalah is absent for Al-Fatihah, present for Al-Baqarah, '
    'and absent for At-Tawbah',
    (tester) async {
      final builderCalls = <int>[];
      final controller = PageController();
      final view = AppQuranPageView(
        pageController: controller,
        highlights: const [],
        quranPagesCount: 604,
        isDarkMode: false,
        basmallahBuilder: (context, surahNumber) {
          builderCalls.add(surahNumber);
          return SizedBox(key: ValueKey('custom_basmallah_$surahNumber'));
        },
      );

      Future<({int appMarkers, int customMarkers})> pumpSurah(
        int surahNumber,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => view.basmallahBuilder(context, surahNumber),
            ),
          ),
        );
        return (
          appMarkers: find
              .byKey(ValueKey('app_structural_basmallah_$surahNumber'))
              .evaluate()
              .length,
          customMarkers: find
              .byKey(ValueKey('custom_basmallah_$surahNumber'))
              .evaluate()
              .length,
        );
      }

      final fatihah = await pumpSurah(1);
      expect(fatihah.appMarkers, 0);
      expect(fatihah.customMarkers, 0);
      expect(builderCalls, isEmpty);

      final baqarah = await pumpSurah(2);
      expect(baqarah.appMarkers, 1);
      expect(baqarah.customMarkers, 1);
      expect(builderCalls, [2]);

      final tawbah = await pumpSurah(9);
      expect(tawbah.appMarkers, 0);
      expect(tawbah.customMarkers, 0);
      expect(builderCalls, [2]);

      controller.dispose();
    },
  );

  testWidgets('maps kids visual pages to canonical Quran page callbacks', (
    tester,
  ) async {
    final controller = PageController();
    final changedPages = <int>[];
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppQuranPageView(
          pageController: controller,
          highlights: const [],
          isDarkMode: false,
          pageOrder: QuranPageOrderPolicy.kidsFatihahFirstReverse,
          onPageChanged: changedPages.add,
        ),
      ),
    );

    final pageViewFinder = find.byType(PageView);
    final pageView = tester.widget<PageView>(pageViewFinder);
    final delegate = pageView.childrenDelegate as SliverChildBuilderDelegate;
    final pageViewContext = tester.element(pageViewFinder);
    final firstPage = delegate.builder(pageViewContext, 0)!;
    final secondPage = delegate.builder(pageViewContext, 1)!;

    final firstContent = _singlePageContent(firstPage);
    final secondContent = _singlePageContent(secondPage);
    expect(firstContent.guard.pageNumber, 1);
    expect(firstContent.quranPage.pageIndex, 1);
    expect(firstContent.quranPage.page.pageNumber, 1);
    expect(secondContent.guard.pageNumber, 604);
    expect(secondContent.quranPage.pageIndex, 604);
    expect(secondContent.quranPage.page.pageNumber, 604);

    final pages = GetPage()..getQuran(604);
    final canonicalLastPage = pages.staticPages[603];
    expect(
      secondContent.quranPage.page.ayahs.map((ayah) => ayah.id),
      canonicalLastPage.ayahs.map((ayah) => ayah.id),
    );

    final firstTurn = controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 50),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await firstTurn;
    final secondTurn = controller.animateToPage(
      2,
      duration: const Duration(milliseconds: 50),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await secondTurn;

    expect(changedPages, [604, 603]);
  });

  testWidgets('uses canonical order by default for adult readers', (
    tester,
  ) async {
    final controller = PageController();
    final changedPages = <int>[];
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppQuranPageView(
          pageController: controller,
          highlights: const [],
          isDarkMode: false,
          onPageChanged: changedPages.add,
        ),
      ),
    );

    final turn = controller.animateToPage(
      1,
      duration: const Duration(milliseconds: 50),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await turn;

    expect(changedPages, [2]);
  });

  testWidgets(
    'matches QCF line offsets for canonical and reversed page order',
    (tester) async {
      await tester.runAsync(
        () => qcf_repository.QuranRepository.instance.ensureLoaded(604),
      );
      final controller = PageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AppQuranPageView(
            pageController: controller,
            highlights: const [],
            isDarkMode: false,
          ),
        ),
      );

      final pageViewFinder = find.byType(PageView);
      final pageView = tester.widget<PageView>(pageViewFinder);
      final delegate = pageView.childrenDelegate as SliverChildBuilderDelegate;
      final pageViewContext = tester.element(pageViewFinder);
      final packageOffsets =
          qcf_repository.QuranRepository.instance.wordOffsets;

      for (var index = 0; index < 604; index++) {
        final content = _singlePageContent(
          delegate.builder(pageViewContext, index)!,
        ).quranPage;
        expect(content.lineOffsets, packageOffsets[index]);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: AppQuranPageView(
            pageController: controller,
            highlights: const [],
            isDarkMode: false,
            pageOrder: QuranPageOrderPolicy.kidsFatihahFirstReverse,
          ),
        ),
      );

      final reversedFinder = find.byType(PageView);
      final reversedPageView = tester.widget<PageView>(reversedFinder);
      final reversedDelegate =
          reversedPageView.childrenDelegate as SliverChildBuilderDelegate;
      final reversedSecondPage = _singlePageContent(
        reversedDelegate.builder(tester.element(reversedFinder), 1)!,
      ).quranPage;
      final reversedFirstPage = _singlePageContent(
        reversedDelegate.builder(tester.element(reversedFinder), 0)!,
      ).quranPage;

      expect(reversedFirstPage.pageIndex, 1);
      expect(reversedFirstPage.lineOffsets, packageOffsets[0]);
      expect(reversedSecondPage.pageIndex, 604);
      expect(reversedSecondPage.lineOffsets, packageOffsets[603]);
    },
  );

  testWidgets(
    'adapts reader highlights with refresh and last-wins precedence',
    (tester) async {
      final controller = PageController();
      const firstHighlight = qcf.HighlightVerse(
        surah: 1,
        verseNumber: 1,
        page: 1,
        color: Color(0x220D5C55),
      );
      const highlight = qcf.HighlightVerse(
        surah: 1,
        verseNumber: 1,
        page: 1,
        color: Color(0x550D5C55),
      );
      const refreshedHighlight = qcf.HighlightVerse(
        surah: 1,
        verseNumber: 2,
        page: 1,
        color: Color(0x770D5C55),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AppQuranPageView(
            pageController: controller,
            highlights: const [firstHighlight, highlight],
            isDarkMode: false,
          ),
        ),
      );

      final pageViewFinder = find.byType(PageView);
      final pageView = tester.widget<PageView>(pageViewFinder);
      final delegate = pageView.childrenDelegate as SliverChildBuilderDelegate;
      final page = delegate.builder(tester.element(pageViewFinder), 0)!;
      final content = _singlePageContent(page).quranPage;

      expect(content.bookmarkIndex.lookup(1, 1), same(highlight));
      expect(content.wordHighlightIndex.lookup(1, 1, 0), isNull);
      expect(content.lineOffsets, isNotEmpty);
      expect(content.forceFitConstraints, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: AppQuranPageView(
            pageController: controller,
            highlights: const [refreshedHighlight],
            isDarkMode: false,
          ),
        ),
      );

      final updatedFinder = find.byType(PageView);
      final updatedPageView = tester.widget<PageView>(updatedFinder);
      final updatedDelegate =
          updatedPageView.childrenDelegate as SliverChildBuilderDelegate;
      final updatedContent = _singlePageContent(
        updatedDelegate.builder(tester.element(updatedFinder), 0)!,
      ).quranPage;

      expect(updatedContent.bookmarkIndex.lookup(1, 1), isNull);
      expect(
        updatedContent.bookmarkIndex.lookup(1, 2),
        same(refreshedHighlight),
      );
    },
  );
}

({QuranPageFontGuard guard, qcf.QuranSinglePageWidget quranPage})
_singlePageContent(Widget page) {
  final column = page as Column;
  final expanded = column.children.single as Expanded;
  final guard = expanded.child as QuranPageFontGuard;
  final repaintBoundary = guard.child as RepaintBoundary;
  final zoomablePage = repaintBoundary.child as MushafZoomablePage;
  return (
    guard: guard,
    quranPage: zoomablePage.child as qcf.QuranSinglePageWidget,
  );
}
