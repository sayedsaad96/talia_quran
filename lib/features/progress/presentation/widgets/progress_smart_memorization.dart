part of '../pages/progress_page.dart';

class _SmartMemorizationCard extends StatelessWidget {
  const _SmartMemorizationCard({required this.progress, required this.isDark});
  final OverallProgress progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Adult Track Stats
          if (progress.smartMemorizedAyahs > 0 ||
              progress.smartReviewAyahs > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_rounded,
                    color: primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.l10n.adultsTrack,
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ProgressBarRow(
                    row: _DetailRow(
                      label: context.l10n.memorizedTerm,
                      current: progress.smartMemorizedAyahs,
                      total: 6236,
                      color: const Color(0xFF2D8E4C),
                    ),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.reviewingPrefix,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '${progress.smartReviewAyahs}',
                          style: AppTypography.labelMedium.copyWith(
                            color: const Color(0xFFFF8C42),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (progress.kidsPoints > 0) const Divider(height: 32),
          ],

          // Kids Track Stats
          if (progress.kidsPoints > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  context.l10n.kidsTrack,
                  style: AppTypography.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: context.l10n.points,
                    value: '${progress.kidsPoints}',
                    icon: Icons.military_tech_rounded,
                    color: AppColors.primary,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    label: context.l10n.stars,
                    value: '${progress.kidsStars}',
                    icon: Icons.star_rounded,
                    color: AppColors.gold,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Certificates Section ─────────────────────────────────────────────────────
