part of 'family_dashboard_page.dart';

// ─── Family summary banner ────────────────────────────────────────────────────

class _FamilySummaryBanner extends StatelessWidget {
  const _FamilySummaryBanner({required this.dashboard});
  final FamilyDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final activeCount = dashboard.totalActiveToday;
    final totalPoints = dashboard.totalPointsToday;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A6B38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(TaliaIcons.family, color: Colors.white, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.familyDashboardTodaySummaryTitle,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.familyDashboardTodaySummary(
                    LocaleNumberFormatter.format(
                      (activeCount).toString(),
                      context.l10n.localeName,
                    ),
                    LocaleNumberFormatter.format(
                      (totalPoints).toString(),
                      context.l10n.localeName,
                    ),
                  ),
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Child card ───────────────────────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cardColor = context.tokens.card;
    final isActive = child.isActiveToday;

    return Semantics(
      label:
          '${child.shownName(context.l10n)}${isActive ? ' — ${context.l10n.familyDashboardChildActiveToday(LocaleNumberFormatter.format((child.todayPoints).toString(), context.l10n.localeName))}' : ''}',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: () => context.push(
          AppRoutes.childDetail,
          extra: ChildDetailRouteArgs(
            child: child,
            cubit: context.read<FamilyDashboardCubit>(),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + active indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      child.avatarEmoji ?? (child.isLocal ? '👨‍👧' : '🧒'),
                      style: AppTypography.headlineLarge,
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Name
              Text(
                child.shownName(context.l10n),
                style: AppTypography.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (child.remoteSummary?.detailsLoading ?? false) ...[
                const SizedBox(height: AppSpacing.xs),
                const LinearProgressIndicator(
                  key: ValueKey('family-child-details-loading'),
                ),
              ],
              if (child.childAge case final age?)
                Text(
                  context.l10n.childAgeYears(
                    age,
                    LocaleNumberFormatter.format(
                      (age).toString(),
                      context.l10n.localeName,
                    ),
                  ),
                  style: AppTypography.labelSmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // Local badge
              if (child.isLocal) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    context.l10n.familyDashboardLocalBadge,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Level progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.kidsLevelValue(
                          LocaleNumberFormatter.format(
                            (child.currentLevel).toString(),
                            context.l10n.localeName,
                          ),
                        ),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (child.currentStreak > 0)
                        Text(
                          '🔥 ${child.currentStreak}',
                          style: AppTypography.labelSmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    child: LinearProgressIndicator(
                      value: child.levelProgress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(
                        0xFF0D5C53,
                      ).withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActive
                        ? context.l10n.familyDashboardChildActiveToday(
                            LocaleNumberFormatter.format(
                              (child.todayPoints).toString(),
                              context.l10n.localeName,
                            ),
                          )
                        : context.l10n.familyDashboardChildNoActivity,
                    style: AppTypography.labelSmall.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : context.tokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add child card ───────────────────────────────────────────────────────────

class _AddChildCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      onTap: () => _showAddChildOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: context.tokens.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TaliaIcons.add,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                context.l10n.familyDashboardAddChild,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty placeholder ────────────────────────────────────────────────────────

class _EmptyFamilyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TaliaIcons.family, size: 80, color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.familyDashboardNoChildren,
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.familyDashboardNoChildrenHint,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _showAddChildOptions(context),
              icon: const Icon(TaliaIcons.qrScan),
              label: Text(context.l10n.familyDashboardAddChild),
            ),
          ],
        ),
      ),
    );
  }
}
