import 'package:flutter/material.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_spacing.dart';

/// Ensures QCF fonts for a specific Quran page are loaded into Flutter engine
/// before rendering the page. Displays a high-quality Shimmer loading placeholder
/// while fonts are loading to prevent broken text rendering.
class QuranPageFontGuard extends StatefulWidget {
  const QuranPageFontGuard({
    super.key,
    required this.pageNumber,
    required this.isDark,
    required this.child,
  });

  final int pageNumber;
  final bool isDark;
  final Widget child;

  @override
  State<QuranPageFontGuard> createState() => _QuranPageFontGuardState();
}

class _QuranPageFontGuardState extends State<QuranPageFontGuard> {
  bool _isFontLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkAndLoadFont();
  }

  @override
  void didUpdateWidget(covariant QuranPageFontGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _checkAndLoadFont();
    }
  }

  void _checkAndLoadFont() {
    if (qcf.QcfFontLoader.isFontLoaded(widget.pageNumber)) {
      if (!_isFontLoaded) {
        setState(() => _isFontLoaded = true);
      }
      return;
    }

    _isFontLoaded = false;
    qcf.QcfFontLoader.ensureFontLoaded(widget.pageNumber).then((_) {
      if (mounted) {
        setState(() => _isFontLoaded = true);
      }
    }).catchError((_) {
      if (mounted) {
        setState(() => _isFontLoaded = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isFontLoaded || qcf.QcfFontLoader.isFontLoaded(widget.pageNumber)) {
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
        ? const Color(0xFF1E2D35)
        : const Color(0xFFE8DFD1);
    final highlightColor = isDark
        ? const Color(0xFF2A3F4B)
        : const Color(0xFFF7F2E9);
    final goldAccent = isDark
        ? const Color(0xFFC8A55B).withValues(alpha: 0.3)
        : const Color(0xFFB08930).withValues(alpha: 0.3);

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
                          borderRadius: BorderRadius.circular(4),
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
