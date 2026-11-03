import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';

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
    this.readCountdown,
    this.onPageTap,
  });

  final int pageNumber;
  final int hizbNumber;
  final Color accent;
  final Color bg;
  final bool showReadConfirmed;

  /// Reading countdown supplied by the reader; it is not displayed.
  final Duration? readCountdown;

  /// Opens the Quick Navigation sheet. Null keeps the indicator static.
  final VoidCallback? onPageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              context.l10n.hizbNumberLabel(context.numText(hizbNumber)),
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
            label: '${context.l10n.page} ${context.numText(pageNumber)}',
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
                    context.numText(pageNumber),
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
          const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }
}
