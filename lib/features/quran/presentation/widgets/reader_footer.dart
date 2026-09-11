import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';

/// Bottom bar of the adult Mushaf reader (presentation only).
///
/// Moved verbatim from `QuranReaderPage` (`_MushafFooter`) as a
/// behavior-preserving refactor. All reading logic stays in the page/cubits.
///
/// Note: [accent] carries the primary guidance color (not gold) — the pill
/// and confirmation use it for legibility on parchment (gold text would fail
/// contrast). Gold remains reserved for achievement surfaces per DESIGN.md.
class ReaderFooter extends StatelessWidget {
  const ReaderFooter({
    super.key,
    required this.pageNumber,
    required this.hizbNumber,
    required this.accent,
    required this.bg,
    required this.showReadConfirmed,
    this.onPageTap,
  });

  final int pageNumber;
  final int hizbNumber;
  final Color accent;
  final Color bg;
  final bool showReadConfirmed;

  /// Opens the Quick Navigation sheet. Null keeps the indicator static.
  final VoidCallback? onPageTap;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              context.l10n.hizbNumberLabel(
                MushafHizbHelper.toArabicNumber(hizbNumber),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontFamily: 'Amiri',
                fontSize: 13,
                color: accent,
                height: 1.5,
              ),
            ),
          ),
          Semantics(
            label: '${context.l10n.page} $pageNumber',
            button: onPageTap != null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                onTap: onPageTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.itemGap,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    MushafHizbHelper.toArabicNumber(pageNumber),
                    style: AppTypography.titleMedium.copyWith(
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      color: accent,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedOpacity(
              opacity: showReadConfirmed ? 1 : 0,
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: accent, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        context.l10n.readPageConfirmed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontFamily: 'Amiri',
                          color: accent,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
