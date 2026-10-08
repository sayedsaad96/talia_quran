import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
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

  /// Reading time still needed before the page counts. Non-null while the
  /// page is being counted; a ring fills over this duration.
  final Duration? readCountdown;

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
          Expanded(
            child: !showReadConfirmed && readCountdown != null
                ? _ReadCountdown(
                    key: ValueKey(pageNumber),
                    duration: readCountdown!,
                    accent: accent,
                  )
                : AnimatedOpacity(
                    opacity: showReadConfirmed ? 1 : 0,
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    child: _ReadStatus(
                      icon: Icon(
                        TaliaIcons.checkCircleFilled,
                        color: accent,
                        size: 16,
                      ),
                      label: context.l10n.readPageConfirmed,
                      color: accent,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A small ring that fills while the page's reading time runs.
class _ReadCountdown extends StatelessWidget {
  const _ReadCountdown({
    super.key,
    required this.duration,
    required this.accent,
  });

  final Duration duration;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = accent.withValues(alpha: 0.7);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return _ReadStatus(
      icon: SizedBox(
        key: const Key('reader_read_countdown'),
        width: 14,
        height: 14,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: disableAnimations ? Duration.zero : duration,
          builder: (context, value, _) => CircularProgressIndicator(
            value: value,
            strokeWidth: 2,
            color: muted,
            backgroundColor: accent.withValues(alpha: 0.15),
          ),
        ),
      ),
      label: context.l10n.readPageCounting,
      color: muted,
    );
  }
}

class _ReadStatus extends StatelessWidget {
  const _ReadStatus({
    required this.icon,
    required this.label,
    required this.color,
  });

  final Widget icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                fontFamily: 'Amiri',
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
