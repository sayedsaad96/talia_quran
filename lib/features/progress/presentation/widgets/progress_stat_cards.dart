part of '../pages/progress_page.dart';

/// Counts up from 0 to [value] once, then tweens between later values.
/// Respects the platform "reduce motion" setting.
class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return Text(context.numText(value), style: style);
    return TweenAnimationBuilder<double>(
      // `begin` only applies to the first build; later value changes
      // animate from wherever the count currently is.
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text(context.numText(v.round()), style: style),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays, required this.isDark});
  final int streakDays;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final unit = context.l10n.progressStreakDaysUnit(streakDays);
    return Semantics(
      container: true,
      label: '${context.l10n.streak}: ${context.numText(streakDays)} $unit',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.streakOrange, AppColors.streakOrangeDeep],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.streakOrange.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.sm),
            _AnimatedCount(
              value: streakDays,
              style: AppTypography.displaySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              unit,
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            Text(
              context.l10n.streak,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.isDark,
    required this.color,
    this.onTap,
    this.levelProgress,
    this.levelProgressLabel,
  });

  final String label;
  final int value;
  final String unit;
  final IconData icon;
  final bool isDark;
  final Color color;
  final VoidCallback? onTap;

  /// Optional 0..1 bar under the value (used by the XP card).
  final double? levelProgress;
  final String? levelProgressLabel;

  @override
  Widget build(BuildContext context) {
    final surface = context.tokens.card;
    final border = context.tokens.divider;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    final levelProgress = this.levelProgress;

    return Semantics(
      container: true,
      button: onTap != null,
      label: '$label: ${context.numText(value)} $unit',
      excludeSemantics: true,
      child: Material(
        color: surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const Spacer(),
                    if (onTap != null)
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.chevron_left_rounded
                            : Icons.chevron_right_rounded,
                        size: 20,
                        color: context.tokens.textHint,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _AnimatedCount(
                  value: value,
                  style: AppTypography.displaySmall.copyWith(
                    color: context.tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  unit,
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: context.tokens.textHint,
                  ),
                ),
                if (levelProgress != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    child: LinearProgressIndicator(
                      value: levelProgress.clamp(0.0, 1.0),
                      minHeight: 4,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.12),
                      semanticsLabel: levelProgressLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Next Milestone ───────────────────────────────────────────────────────────

/// Points the user at the locked achievement they are closest to, so the
/// page always answers "what's next?".
class _NextMilestoneCard extends StatelessWidget {
  const _NextMilestoneCard({required this.milestone, required this.isDark});

  final Achievement? milestone;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.accent;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    final milestone = this.milestone;

    if (milestone == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: radius,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.gold,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.progressAllAchievementsUnlocked,
                style: AppTypography.bodyMedium.copyWith(
                  color: context.tokens.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final title = context.localizedAchievementTitle(milestone);
    return Semantics(
      button: true,
      label:
          '${context.l10n.progressNextMilestoneTitle}: $title, '
          '${context.l10n.countOfTotal(LocaleNumberFormatter.format((milestone.currentValue).toString(), context.l10n.localeName), LocaleNumberFormatter.format((milestone.targetValue).toString(), context.l10n.localeName))}',
      excludeSemantics: true,
      child: Material(
        color: accent.withValues(alpha: 0.08),
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => _showAchievementDetailSheet(context, milestone, isDark),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                _AchievementBadgeShape(
                  achievement: milestone,
                  isDark: isDark,
                  isUnlocked: false,
                  size: 48,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.progressNextMilestoneTitle,
                        style: AppTypography.labelSmall.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: context.tokens.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXs,
                        ),
                        child: LinearProgressIndicator(
                          value: milestone.progressPercent,
                          minHeight: 6,
                          color: accent,
                          backgroundColor: accent.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.countOfTotal(
                                LocaleNumberFormatter.format(
                                  (milestone.currentValue).toString(),
                                  context.l10n.localeName,
                                ),
                                LocaleNumberFormatter.format(
                                  (milestone.targetValue).toString(),
                                  context.l10n.localeName,
                                ),
                              ),
                              style: AppTypography.labelSmall.copyWith(
                                color: context.tokens.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            context.l10n.progressNextMilestoneRemaining(
                              LocaleNumberFormatter.format(
                                (milestone.remaining).toString(),
                                context.l10n.localeName,
                              ),
                            ),
                            style: AppTypography.labelSmall.copyWith(
                              color: context.tokens.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Due Reviews Banner ───────────────────────────────────────────────────────

class _DueReviewsBanner extends StatelessWidget {
  const _DueReviewsBanner({
    required this.dueCount,
    required this.hasOverdue,
    required this.onStart,
  });

  final int dueCount;
  final bool hasOverdue;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final color = hasOverdue ? AppColors.warning : AppColors.info;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      // Message on top, action below: fits any width and text scale.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: color, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.progressDueReviewsNudge(
                    dueCount,
                    LocaleNumberFormatter.format(
                      (dueCount).toString(),
                      context.l10n.localeName,
                    ),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: context.tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(context.l10n.progressStartReview),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detailed Progress Card ───────────────────────────────────────────────────
