import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
// ignore: implementation_imports
import 'package:qcf_quran_plus/src/widgets/bsmallah_widget.dart' as qcf_widgets;

import '../../../../core/accessibility/clarity_mode.dart';
import 'mushaf_zoomable_page.dart';
import 'quran_page_font_guard.dart';

/// The reader's guarded QCF leaf, shared by the standalone spread prototype.
class AppQuranPageContent extends StatelessWidget {
  AppQuranPageContent({
    super.key,
    required this.page,
    required this.pageController,
    required this.highlights,
    required this.isDarkMode,
    required this.basmallahBuilder,
    this.onZoomChanged,
    this.onLongPress,
    this.surahHeaderBuilder,
    this.ayahStyle,
    this.isTajweed = true,
  }) {
    RangeError.checkValueInInterval(page.pageNumber, 1, 604, 'pageNumber');
  }

  final qcf.QuranPage page;
  final PageController pageController;
  final List<qcf.HighlightVerse> highlights;
  final bool isDarkMode;
  final bool isTajweed;
  final ValueChanged<bool>? onZoomChanged;
  final void Function(int, int, LongPressStartDetails)? onLongPress;
  final Widget Function(BuildContext, int)? surahHeaderBuilder;
  final Widget Function(BuildContext, int) basmallahBuilder;
  final TextStyle? ayahStyle;

  @override
  Widget build(BuildContext context) => QuranPageFontGuard(
    key: ValueKey('page_font_${page.pageNumber}'),
    pageNumber: page.pageNumber,
    isDark: isDarkMode,
    child: RepaintBoundary(
      child: SystemTextScale(
        child: MushafZoomablePage(
          onZoomChanged: onZoomChanged,
          child: qcf.QuranSinglePageWidget(
            key: ValueKey('page_content_${page.pageNumber}'),
            page: page,
            pageIndex: page.pageNumber,
            pageController: pageController,
            highlights: highlights,
            isDark: isDarkMode,
            isTajweed: isTajweed,
            onLongPress: onLongPress,
            surahHeaderBuilder: surahHeaderBuilder,
            basmallahBuilder: basmallahBuilder,
            ayahStyle: ayahStyle,
          ),
        ),
      ),
    ),
  );
}

/// Limits ambient QCF sizing to one spread pane; normal reader sizing is intact.
class QuranPagePaneViewport extends StatelessWidget {
  const QuranPagePaneViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
        throw FlutterError('A Quran pane requires finite width and height.');
      }
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(size: constraints.biggest),
        child: child,
      );
    },
  );
}

/// Keeps structural basmallah handling identical in reader and profile harness.
Widget Function(BuildContext, int) structuralBasmallahBuilder(
  Widget Function(BuildContext, int)? customBuilder,
) => (context, surahNumber) {
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
