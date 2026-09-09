import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/today_checklist.dart';

class HomeTodayChecklist extends StatelessWidget {
  const HomeTodayChecklist({
    super.key,
    required this.checklist,
    required this.isDark,
  });

  final TodayChecklist checklist;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    return Semantics(
      label: context.l10n.homeTodayTitle,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.homeTodayTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: textColor,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: checklist.progress,
                        strokeWidth: 3,
                        color: primary,
                        backgroundColor: primary.withValues(alpha: 0.12),
                      ),
                      // Clamp text scaling for this compact numeric badge so
                      // very large accessibility font sizes don't overflow
                      // the fixed-size ring; the same information is fully
                      // exposed (and scales normally) via the accessible
                      // task rows below.
                      MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1.3,
                        child: Text(
                          '${checklist.completedCount}/${checklist.tasks.length}',
                          maxLines: 1,
                          style: AppTypography.labelSmall.copyWith(
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final task in checklist.tasks) _TodayRow(task: task, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.task, required this.isDark});
  final TodayTask task;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label = switch (task.kind) {
      TodayTaskKind.reading => context.l10n.homeTodayReading,
      TodayTaskKind.memorize => context.l10n.homeTodayMemorize,
      TodayTaskKind.review => context.l10n.homeTodayReview,
      TodayTaskKind.azkar => context.l10n.homeTodayAzkar,
    };
    final status = task.isComplete
        ? context.l10n.homeTodayDone
        : context.l10n.homeTodayTodo;
    return Semantics(
      button: true,
      label: '$label, $status',
      child: InkWell(
        onTap: () => context.push(task.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                task.isComplete
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.isComplete ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    decoration: task.isComplete
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              if (task.kind == TodayTaskKind.review && task.detail != null)
                Text(
                  task.detail!,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.info,
                  ),
                ),
              Icon(context.forwardChevron, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
