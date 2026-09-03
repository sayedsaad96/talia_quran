import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';

class KhatmahHeroCard extends StatelessWidget {
  const KhatmahHeroCard({
    super.key,
    this.plan,
    required this.isDark,
    this.margin = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final KhatmahPlan? plan;
  final bool isDark;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final currentPlan = plan;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    if (currentPlan == null) {
      return Card(
        margin: margin,
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        elevation: 0,
        child: InkWell(
          key: const Key('khatmah_hero_start_button'),
          onTap: () => context.push('/khatmah/setup'),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primary, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.l10n.khatmahStartAction,
                    style: AppTypography.labelLarge.copyWith(color: primary),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
      );
    }

    final wird = KhatmahSchedulingEngine.todaysWird(
      currentPlan.currentPage,
      currentPlan.targetPagesPerDay,
    );
    final isPaused = currentPlan.status == KhatmahStatus.paused;

    return Card(
      margin: margin,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      elevation: 0,
      child: InkWell(
        key: isPaused ? const Key('khatmah_hero_resume_button') : null,
        onTap: () => context.push(
          isPaused
              ? '/khatmah/dashboard'
              : '/quran/page/${wird.startPage}?mode=khatmah',
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      currentPlan.title,
                      style: AppTypography.labelLarge.copyWith(color: primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(currentPlan.progressPercentage * 100).toStringAsFixed(0)}%',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                child: LinearProgressIndicator(
                  value: currentPlan.progressPercentage,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isPaused
                    ? context.l10n.khatmahPausedSummary
                    : 'Today: pages ${wird.startPage} - ${wird.endPage}',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (currentPlan.dedication.isDedicated &&
                  currentPlan.dedication.recipientName != null &&
                  currentPlan.dedication.recipientName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Dedicated to: ${currentPlan.dedication.recipientName}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
