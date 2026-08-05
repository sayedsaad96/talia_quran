import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';

import 'quran_page_font_guard.dart';

/// A wrapper around QuranPageView that ensures QCF fonts for each page are
/// fully loaded before rendering, preventing broken font glyphs on initial page load.
class AppQuranPageView extends StatelessWidget {
  final PageController pageController;
  final Function(int)? onPageChanged;
  final List<qcf.HighlightVerse> highlights;
  final Widget? topBar;
  final Widget? bottomBar;
  final void Function(
    int surahNumber,
    int verseNumber,
    LongPressStartDetails details,
  )?
  onLongPress;
  final int quranPagesCount;
  final Widget Function(BuildContext context, int surahNumber)?
  surahHeaderBuilder;
  final Widget Function(BuildContext context, int surahNumber)?
  basmallahBuilder;
  final bool isDarkMode;
  final TextStyle? ayahStyle;
  final Color? pageBackgroundColor;
  final bool isTajweed;

  final List<qcf.QuranPage> pages;

  AppQuranPageView({
    super.key,
    required this.pageController,
    this.onPageChanged,
    required this.highlights,
    this.onLongPress,
    this.quranPagesCount = 604,
    this.topBar,
    this.bottomBar,
    this.surahHeaderBuilder,
    this.basmallahBuilder,
    this.ayahStyle,
    this.pageBackgroundColor,
    this.isTajweed = true,
    required this.isDarkMode,
  }) : pages = _loadQuranData(quranPagesCount);

  static List<qcf.QuranPage>? _cachedPages;

  static List<qcf.QuranPage> _loadQuranData(int count) {
    if (_cachedPages != null && _cachedPages!.length == count) {
      return _cachedPages!;
    }
    final processor = GetPage();
    processor.getQuran(count);
    _cachedPages = processor.staticPages;
    return _cachedPages!;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: pageBackgroundColor ?? Colors.transparent,
        child: PageView.builder(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          allowImplicitScrolling: true,
          controller: pageController,
          itemCount: pages.length,
          onPageChanged: (index) {
            final int page = index + 1;
            onPageChanged?.call(page);
          },
          itemBuilder: (context, index) {
            final int pageNum = index + 1;

            return Column(
              children: [
                ?topBar,
                Expanded(
                  child: QuranPageFontGuard(
                    pageNumber: pageNum,
                    isDark: isDarkMode,
                    child: RepaintBoundary(
                      child: qcf.QuranSinglePageWidget(
                        key: ValueKey('page_content_$pageNum'),
                        isTajweed: isTajweed,
                        page: pages[index],
                        pageIndex: pageNum,
                        highlights: highlights,
                        onLongPress: onLongPress,
                        pageController: pageController,
                        surahHeaderBuilder: surahHeaderBuilder,
                        basmallahBuilder: basmallahBuilder,
                        ayahStyle: ayahStyle,
                        isDark: isDarkMode,
                      ),
                    ),
                  ),
                ),
                ?bottomBar,
              ],
            );
          },
        ),
      ),
    );
  }
}
