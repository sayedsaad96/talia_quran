import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';

/// One-time long-press hint banner of the adult Mushaf reader.
///
/// Moved verbatim from `QuranReaderPage` (`_LongPressHintBanner`) as a
/// behavior-preserving refactor.
class LongPressHintBanner extends StatelessWidget {
  const LongPressHintBanner({
    super.key,
    required this.accent,
    required this.bg,
    required this.onDismiss,
  });

  final Color accent;
  final Color bg;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.quranLongPressHint,
                style: AppTypography.bodySmall.copyWith(
                  fontFamily: 'Amiri',
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, color: accent, size: 18),
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.close,
            ),
          ],
        ),
      ),
    );
  }
}
