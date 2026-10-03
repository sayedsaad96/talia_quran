import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/services/get_page.dart';
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/widgets/bsmallah_widget.dart' as qcf_widgets;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/widgets/quran_page/highlight_index.dart'
    as qcf_indexes;

import 'mushaf_page_flip_physics.dart';
import 'quran_page_font_guard.dart';
import '../../domain/services/quran_page_order_policy.dart';

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
  }) : basmallahBuilder = _structuralBasmallahBuilder(basmallahBuilder);

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

  static Widget Function(BuildContext, int) _structuralBasmallahBuilder(
    Widget Function(BuildContext context, int surahNumber)? customBuilder,
  ) {
    return (context, surahNumber) {
      if (surahNumber == 1 || surahNumber == 9) {
        return const SizedBox.shrink();
      }

      return KeyedSubtree(
        key: ValueKey('app_structural_basmallah_$surahNumber'),
        child:
            customBuilder?.call(context, surahNumber) ??
            qcf_widgets.BasmallahWidget(surahNumber),
      );
    };
  }

  @override
  State<AppQuranPageView> createState() => _AppQuranPageViewState();
}

class _AppQuranPageViewState extends State<AppQuranPageView> {
  static List<qcf.QuranPage>? _cachedPages;
  static List<Map<int, Map<String, int>>>? _cachedLineOffsets;

  /// Fractional page offset (e.g. 1.72 = 72% through page index 1).
  final ValueNotifier<double> _pageOffsetNotifier = ValueNotifier(0);

  late final List<qcf.QuranPage> _pages;
  late final List<Map<int, Map<String, int>>> _lineOffsets;
  final qcf_indexes.MemoizedBookmarkIndex _bookmarkIndexer =
      qcf_indexes.MemoizedBookmarkIndex();
  late qcf_indexes.BookmarkIndex _bookmarkIndex;
  bool _pageZoomed = false;

  @override
  void initState() {
    super.initState();
    _pages = _loadQuranData(widget.quranPagesCount);
    _lineOffsets = _loadLineOffsets(_pages);
    _bookmarkIndex = _bookmarkIndexer.refresh(widget.highlights);
    widget.pageController.addListener(_onControllerScroll);
  }

  @override
  void didUpdateWidget(covariant AppQuranPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bookmarkIndex = _bookmarkIndexer.refresh(widget.highlights);
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

  static List<Map<int, Map<String, int>>> _loadLineOffsets(
    List<qcf.QuranPage> pages,
  ) {
    if (_cachedLineOffsets != null &&
        _cachedLineOffsets!.length == pages.length) {
      return _cachedLineOffsets!;
    }

    final offsets = <Map<int, Map<String, int>>>[];
    final runningCounts = <String, int>{};
    final wordSplitRegex = RegExp(r'\s+');
    final digitsRegex = RegExp(r'^[\d٠-٩]+$');

    for (final page in pages) {
      final pageOffsets = <int, Map<String, int>>{};
      offsets.add(pageOffsets);
      for (var lineIndex = 0; lineIndex < page.lines.length; lineIndex++) {
        final lineOffsets = <String, int>{};
        pageOffsets[lineIndex] = lineOffsets;
        for (final ayah in page.lines[lineIndex].ayahs) {
          final key = '${ayah.surahNumber}-${ayah.ayahNumber}';
          final offset = runningCounts[key] ?? 0;
          lineOffsets[key] = offset;
          final wordCount = ayah.ayah
              .replaceAll('\n', ' ')
              .trim()
              .split(wordSplitRegex)
              .where((word) => word.isNotEmpty && !digitsRegex.hasMatch(word))
              .length;
          runningCounts[key] = offset + wordCount;
        }
      }
    }

    _cachedLineOffsets = offsets;
    return offsets;
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
                    child: QuranPageFontGuard(
                      pageNumber: pageNum,
                      isDark: widget.isDarkMode,
                      child: RepaintBoundary(
                        child: MushafZoomablePage(
                          onZoomChanged: (zoomed) {
                            if (mounted && _pageZoomed != zoomed) {
                              setState(() => _pageZoomed = zoomed);
                            }
                          },
                          child: qcf.QuranSinglePageWidget(
                            key: ValueKey('page_content_$pageNum'),
                            isTajweed: widget.isTajweed,
                            page: _pages[pageNum - 1],
                            pageIndex: pageNum,
                            wordHighlightIndex:
                                qcf_indexes.WordHighlightIndex.empty,
                            bookmarkIndex: _bookmarkIndex,
                            onLongPress: widget.onLongPress,
                            pageController: widget.pageController,
                            surahHeaderBuilder: widget.surahHeaderBuilder,
                            basmallahBuilder: widget.basmallahBuilder,
                            ayahStyle: widget.ayahStyle,
                            isDark: widget.isDarkMode,
                            lineOffsets: _lineOffsets[pageNum - 1],
                            forceFitConstraints: false,
                          ),
                        ),
                      ),
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

/// Pinch-zoom and double-tap zoom for a mushaf page.
///
/// Pan stays disabled at rest so single-finger swipes keep turning pages;
/// it is only enabled while zoomed, when the drag belongs to the content.
/// Double-tap toggles between 1x and a reading-friendly 2.25x centered on
/// the tapped point.
class MushafZoomablePage extends StatefulWidget {
  const MushafZoomablePage({
    super.key,
    required this.child,
    this.onZoomChanged,
  });

  final Widget child;
  final ValueChanged<bool>? onZoomChanged;

  @override
  State<MushafZoomablePage> createState() => _MushafZoomablePageState();
}

class _MushafZoomablePageState extends State<MushafZoomablePage> {
  static const _maxScale = 3.0;
  static const _doubleTapScale = 2.25;

  final TransformationController _controller = TransformationController();
  Offset? _doubleTapPosition;
  bool _lastZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_reportZoomChange);
  }

  void _reportZoomChange() {
    final zoomed = _isZoomed(_controller.value);
    if (zoomed == _lastZoomed) return;
    _lastZoomed = zoomed;
    widget.onZoomChanged?.call(zoomed);
  }

  bool _isZoomed(Matrix4 matrix) => matrix.getMaxScaleOnAxis() > 1.01;

  void _handleDoubleTap() {
    final position = _doubleTapPosition;
    if (_isZoomed(_controller.value)) {
      _controller.value = Matrix4.identity();
      return;
    }
    if (position == null) {
      _controller.value = Matrix4.identity()
        ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
      return;
    }
    // Scale around the tapped point: T(p) · S(s) · T(-p).
    _controller.value = Matrix4.identity()
      ..translateByDouble(position.dx, position.dy, 0, 1)
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1)
      ..translateByDouble(-position.dx, -position.dy, 0, 1);
  }

  @override
  void dispose() {
    _controller.removeListener(_reportZoomChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Matrix4>(
      valueListenable: _controller,
      builder: (context, matrix, child) {
        return InteractiveViewer(
          transformationController: _controller,
          panEnabled: _isZoomed(matrix),
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: _maxScale,
          child: GestureDetector(
            onDoubleTapDown: (details) =>
                _doubleTapPosition = details.localPosition,
            onDoubleTap: _handleDoubleTap,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
