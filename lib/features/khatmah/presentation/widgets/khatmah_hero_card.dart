import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';

class KhatmahHeroCard extends StatelessWidget {
  const KhatmahHeroCard({
    super.key,
    required this.plan,
    required this.isDark,
    this.margin = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
  });

  final KhatmahPlan plan;
  final bool isDark;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final wird = KhatmahSchedulingEngine.todaysWird(
      plan.currentPage,
      plan.targetPagesPerDay,
    );
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Card(
      margin: margin,
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push(
          '/quran/page/${wird.startPage}?mode=khatmah',
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
                      plan.title,
                      style: AppTypography.labelLarge.copyWith(color: primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${(plan.progressPercentage * 100).toStringAsFixed(0)}%',
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
                  value: plan.progressPercentage,
                  backgroundColor: primary.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Today: pages ${wird.startPage} - ${wird.endPage}',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (plan.dedication.isDedicated &&
                  plan.dedication.recipientName != null &&
                  plan.dedication.recipientName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    'Dedicated to: ${plan.dedication.recipientName}',
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
