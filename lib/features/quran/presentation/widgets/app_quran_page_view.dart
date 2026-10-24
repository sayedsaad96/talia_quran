import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';

import 'app_quran_page_content.dart';

import 'mushaf_page_flip_physics.dart';

import '../../domain/services/quran_page_order_policy.dart';

export 'mushaf_zoomable_page.dart';

/// A wrapper around QuranPageView that ensures QCF fonts for each page are
/// fully loaded before rendering, preventing broken font glyphs on initial page load.
///
/// Now includes a [MushafPageCurlOverlay] that draws a soft page-curl shadow
/// while the user swipes between pages, giving the feel of a real Mushaf.
class AppQuranPageView extends StatefulWidget {
  AppQuranPageView({
    super.key,
    required this.pageController,
    this.onPageChanged,
    required this.highlights,
    this.onLongPress,
    this.quranPagesCount = 604,
    this.pageOrder = QuranPageOrderPolicy.canonical,
    this.topBar,
    this.bottomBar,
    this.surahHeaderBuilder,
    Widget Function(BuildContext context, int surahNumber)? basmallahBuilder,
    this.ayahStyle,
    this.pageBackgroundColor,
    this.isTajweed = true,
    required this.isDarkMode,
  }) : basmallahBuilder = structuralBasmallahBuilder(basmallahBuilder);

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
  final QuranPageOrderPolicy pageOrder;
  final Widget Function(BuildContext context, int surahNumber)?
  surahHeaderBuilder;
  final Widget Function(BuildContext context, int surahNumber) basmallahBuilder;
  final bool isDarkMode;
  final TextStyle? ayahStyle;
  final Color? pageBackgroundColor;
  final bool isTajweed;

  @override
  State<AppQuranPageView> createState() => _AppQuranPageViewState();
}

class _AppQuranPageViewState extends State<AppQuranPageView> {
  static List<qcf.QuranPage>? _cachedPages;

  /// Fractional page offset (e.g. 1.72 = 72% through page index 1).
  final ValueNotifier<double> _pageOffsetNotifier = ValueNotifier(0);

  late final List<qcf.QuranPage> _pages;
  bool _pageZoomed = false;

  @override
  void initState() {
    super.initState();
    _pages = _loadQuranData(widget.quranPagesCount);
    widget.pageController.addListener(_onControllerScroll);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onControllerScroll);
    _pageOffsetNotifier.dispose();
    super.dispose();
  }

  void _onControllerScroll() {
    final page = widget.pageController.page;
    if (page != null) {
      _pageOffsetNotifier.value = page;
    }
  }

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
    final bgColor = widget.pageBackgroundColor ?? Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MushafPageCurlOverlay(
        pageOffsetNotifier: _pageOffsetNotifier,
        pageColor: bgColor,
        shadowColor: Colors.black,
        child: Container(
          color: bgColor,
          child: PageView.builder(
            physics: _pageZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            allowImplicitScrolling: true,
            controller: widget.pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              if (_pageZoomed) setState(() => _pageZoomed = false);
              final page = widget.pageOrder.canonicalPageForIndex(
                index,
                pageCount: _pages.length,
              );
              widget.onPageChanged?.call(page);
            },
            itemBuilder: (context, index) {
              final pageNum = widget.pageOrder.canonicalPageForIndex(
                index,
                pageCount: _pages.length,
              );

              return Column(
                children: [
                  // Pinned build_runner analyzer cannot parse null-aware elements.
                  // ignore: use_null_aware_elements
                  if (widget.topBar != null) widget.topBar!,
                  Expanded(
                    child: AppQuranPageContent(
                      key: ValueKey('guarded_page_$pageNum'),
                      page: _pages[pageNum - 1],
                      pageController: widget.pageController,
                      highlights: widget.highlights,
                      isDarkMode: widget.isDarkMode,
                      isTajweed: widget.isTajweed,
                      onLongPress: widget.onLongPress,
                      surahHeaderBuilder: widget.surahHeaderBuilder,
                      basmallahBuilder: widget.basmallahBuilder,
                      ayahStyle: widget.ayahStyle,
                      onZoomChanged: (zoomed) {
                        if (mounted && _pageZoomed != zoomed) {
                          setState(() => _pageZoomed = zoomed);
                        }
                      },
                    ),
                  ),
                  // Pinned build_runner analyzer cannot parse null-aware elements.
                  // ignore: use_null_aware_elements
                  if (widget.bottomBar != null) widget.bottomBar!,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
