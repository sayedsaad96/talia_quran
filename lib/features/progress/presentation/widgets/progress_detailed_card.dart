part of '../pages/progress_page.dart';

class _DetailRow {
  const _DetailRow({
    required this.label,
    required this.current,
    required this.total,
    required this.color,
  });
  final String label;
  final int current;
  final int total;
  final Color color;

  double get percentage => total == 0 ? 0 : current / total;
}

class _InfoChip {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.wide = false,
  });
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  /// Takes a full row; for long values such as a surah name.
  final bool wide;
}

/// One decimal for small values so early progress is visible (0.3%),
/// whole numbers once progress is meaningful.
String _formatPercent(BuildContext context, double fraction) {
  final pct = (fraction.clamp(0.0, 1.0)) * 100;
  if (pct == 0 || pct >= 10) {
    return context.digitText('${pct.toStringAsFixed(0)}%');
  }
  return context.digitText('${pct.toStringAsFixed(1)}%');
}

class _DetailedProgressCard extends StatelessWidget {
  const _DetailedProgressCard({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.percentage,
    required this.rows,
    this.extraInfo,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final double percentage;
  final List<_DetailRow> rows;
  final List<_InfoChip>? extraInfo;

  @override
  Widget build(BuildContext context) {
    final surface = context.tokens.card;
    final border = context.tokens.divider;
    final textPrimary = context.tokens.textPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final ring = CircularPercentIndicator(
                radius: 44,
                lineWidth: 6,
                percent: percentage.clamp(0.0, 1.0),
                center: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: iconColor, size: 20),
                        const SizedBox(height: 2),
                        Text(
                          _formatPercent(context, percentage),
                          style: AppTypography.labelSmall.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                progressColor: iconColor,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 600,
              );
              final titleText = Text(
                title,
                style: AppTypography.headlineSmall.copyWith(color: textPrimary),
              );
              final bars = [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _ProgressBarRow(row: row, isDark: isDark),
                  ),
              ];

              // Wide cards keep the ring beside the bars; on phones the
              // bars get the full width so counts never collide.
              if (constraints.maxWidth >= 340) {
                return Row(
                  children: [
                    ring,
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleText,
                          const SizedBox(height: AppSpacing.sm),
                          ...bars,
                        ],
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ring,
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: titleText),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...bars,
                ],
              );
            },
          ),
          // Extra info chips: a 3-column grid that wraps, so any number of
          // chips fits at every width and text scale.
          if (extraInfo != null && extraInfo!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: border, height: 1),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppSpacing.sm;
                final columns = constraints.maxWidth < 280 ? 2 : 3;
                final cell =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final chip in extraInfo!)
                      SizedBox(
                        width: chip.wide ? constraints.maxWidth : cell,
                        child: _InfoChipTile(chip: chip),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChipTile extends StatelessWidget {
  const _InfoChipTile({required this.chip});
  final _InfoChip chip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${chip.label}: ${chip.value}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: chip.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chip.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleSmall.copyWith(
                color: chip.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              chip.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Bar Row ─────────────────────────────────────────────────────────

class _ProgressBarRow extends StatelessWidget {
  const _ProgressBarRow({required this.row, required this.isDark});
  final _DetailRow row;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hintColor = context.tokens.textHint;
    final textPrimary = context.tokens.textPrimary;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: row.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(color: hintColor),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              context.l10n.countOfTotal(
                LocaleNumberFormatter.format(
                  (row.current).toString(),
                  context.l10n.localeName,
                ),
                LocaleNumberFormatter.format(
                  (row.total).toString(),
                  context.l10n.localeName,
                ),
              ),
              style: AppTypography.labelSmall.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 4,
          percent: row.percentage.clamp(0.0, 1.0),
          progressColor: row.color,
          backgroundColor: row.color.withValues(alpha: 0.1),
          barRadius: const Radius.circular(4),
          animation: true,
          animationDuration: 600,
        ),
      ],
    );
  }
}

// ─── Achievement Categories ───────────────────────────────────────────────────
