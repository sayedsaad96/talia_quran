import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/khatmah_plan.dart';

/// Thirty juz cells, each tinted by the share of its pages already read.
/// Tapping a juz opens its first unread page.
class KhatmahJuzMap extends StatelessWidget {
  const KhatmahJuzMap({
    super.key,
    required this.plan,
    required this.onOpenPage,
    this.enabled = true,
  });

  final KhatmahPlan plan;
  final ValueChanged<int> onOpenPage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.accent;
    String number(int value) => context.numText(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.khatmahJuzMapTitle, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: [
            for (var juz = 1; juz <= 30; juz++)
              _JuzCell(
                juz: juz,
                progress: plan.juzProgress(juz),
                accent: accent,
                label: number,
                onTap: enabled
                    ? () => onOpenPage(plan.firstUnreadPageInJuz(juz))
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _JuzCell extends StatelessWidget {
  const _JuzCell({
    required this.juz,
    required this.progress,
    required this.accent,
    required this.label,
    this.onTap,
  });

  final int juz;
  final ({int read, int total}) progress;
  final Color accent;
  final String Function(int) label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final share = progress.read / progress.total;
    final done = progress.read == progress.total;
    return Semantics(
      button: onTap != null,
      label: context.l10n.khatmahJuzMapCell(
        label(juz),
        label(progress.read),
        label(progress.total),
      ),
      excludeSemantics: true,
      child: InkWell(
        key: Key('khatmah_juz_cell_$juz'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
            // Capped so the juz number stays readable on a full cell.
            color: accent.withValues(alpha: 0.06 + 0.4 * share),
          ),
          child: done
              ? Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: context.tokens.textPrimary,
                )
              : Text(
                  label(juz),
                  style: AppTypography.labelSmall.copyWith(
                    color: context.tokens.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}
