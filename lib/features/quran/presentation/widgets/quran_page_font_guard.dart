import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

/// Loads and reports QCF font registration for a canonical Mushaf page.
abstract interface class QuranPageFontLoader {
  bool isFontLoaded(int pageNumber);
  Future<void> ensureFontLoaded(int pageNumber);
}

/// Default bridge to the QCF package loader.
final class QcfPageFontLoader implements QuranPageFontLoader {
  const QcfPageFontLoader();

  @override
  bool isFontLoaded(int pageNumber) =>
      qcf.QcfFontLoader.isFontLoaded(pageNumber);

  @override
  Future<void> ensureFontLoaded(int pageNumber) =>
      qcf.QcfFontLoader.ensureFontLoaded(pageNumber);
}

/// Ensures QCF fonts for a specific Quran page are loaded into Flutter engine
/// before rendering the page. Displays a high-quality Shimmer loading placeholder
/// while fonts are loading to prevent broken text rendering.
class QuranPageFontGuard extends StatefulWidget {
  const QuranPageFontGuard({
    super.key,
    required this.pageNumber,
    required this.isDark,
    required this.child,
    this.fontLoader = const QcfPageFontLoader(),
  });

  final int pageNumber;
  final bool isDark;
  final Widget child;
  final QuranPageFontLoader fontLoader;

  @override
  State<QuranPageFontGuard> createState() => _QuranPageFontGuardState();
}

class _QuranPageFontGuardState extends State<QuranPageFontGuard> {
  int _requestGeneration = 0;
  int? _readyPage;
  QuranPageFontLoader? _readyLoader;

  @override
  void initState() {
    super.initState();
    _checkAndLoadFont();
  }

  @override
  void didUpdateWidget(covariant QuranPageFontGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber ||
        !identical(oldWidget.fontLoader, widget.fontLoader)) {
      _checkAndLoadFont();
    }
  }

  void _checkAndLoadFont() {
    final generation = ++_requestGeneration;
    final page = widget.pageNumber;
    final loader = widget.fontLoader;
    _readyPage = null;
    _readyLoader = null;

    if (loader.isFontLoaded(page)) {
      _markReady(generation, page, loader);
      return;
    }

    try {
      loader.ensureFontLoaded(page).then(
        (_) => _markReady(generation, page, loader),
        onError: (Object error, StackTrace stack) => _markFailed(generation, page, loader),
      );
    } catch (_) {
      _markFailed(generation, page, loader);
    }
  }

  bool _isCurrentRequest(
    int generation,
    int page,
    QuranPageFontLoader loader,
  ) =>
      mounted &&
      generation == _requestGeneration &&
      page == widget.pageNumber &&
      identical(loader, widget.fontLoader);

  void _markReady(int generation, int page, QuranPageFontLoader loader) {
    if (!_isCurrentRequest(generation, page, loader) ||
        !loader.isFontLoaded(page)) {
      return;
    }
    setState(() {
      _readyPage = page;
      _readyLoader = loader;
    });
  }

  void _markFailed(int generation, int page, QuranPageFontLoader loader) {
    if (!_isCurrentRequest(generation, page, loader)) return;
    setState(() {
      _readyPage = null;
      _readyLoader = null;
    });
  }

  @override
  void dispose() {
    _requestGeneration++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_readyPage == widget.pageNumber &&
        identical(_readyLoader, widget.fontLoader) &&
        widget.fontLoader.isFontLoaded(widget.pageNumber)) {
      return widget.child;
    }

    return QuranPageSkeletonLoader(isDark: widget.isDark);
  }
}

/// A shimmer skeleton loader designed to mimic the exact layout of a Mushaf page.
class QuranPageSkeletonLoader extends StatelessWidget {
  const QuranPageSkeletonLoader({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark
        ? AppColors.shimmerBase
        : AppColors.shimmerBaseLight;
    final highlightColor = isDark
        ? AppColors.shimmerHighlight
        : AppColors.shimmerHighlightLight;
    final goldAccent = isDark
        ? AppColors.desertSand.withValues(alpha: 0.3)
        : AppColors.desertSand.withValues(alpha: 0.3);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xs),
            // Decorative Surah Header Placeholder
            Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: goldAccent),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Basmallah Placeholder
            Container(
              height: 28,
              width: 180,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 15 Ayah Lines Placeholder
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const lineCount = 15;
                  final availableHeight = constraints.maxHeight;
                  final lineHeight = (availableHeight / lineCount) - 8;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(lineCount, (index) {
                      // Alternate line widths for natural Quran page appearance
                      final double widthFactor = switch (index) {
                        0 => 0.85,
                        14 => 0.65,
                        _ => 0.95 + (index % 3 == 0 ? 0.05 : -0.02),
                      };

                      return Container(
                        height: lineHeight.clamp(14.0, 32.0),
                        width: constraints.maxWidth * widthFactor,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}
