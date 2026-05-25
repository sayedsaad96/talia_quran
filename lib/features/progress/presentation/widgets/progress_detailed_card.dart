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
  });
  final String label;
  final String value;
  final Color color;
  final bool isDark;
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
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular progress
              CircularPercentIndicator(
                radius: 44,
                lineWidth: 6,
                percent: percentage.clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                progressColor: iconColor,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                circularStrokeCap: CircularStrokeCap.round,
                animation: true,
                animationDuration: 600,
              ),
              const SizedBox(width: AppSpacing.lg),
              // Details column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSmall.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...rows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _ProgressBarRow(row: row, isDark: isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Extra info chips
          if (extraInfo != null && extraInfo!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: border, height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: extraInfo!.map((chip) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: chip.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: chip.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          chip.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          chip.value,
                          style: AppTypography.labelMedium.copyWith(
                            color: chip.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
    final hintColor = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

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
            Text(
              row.label,
              style: AppTypography.labelSmall.copyWith(color: hintColor),
            ),
            const Spacer(),
            Text(
              '${row.current} / ${row.total}',
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
