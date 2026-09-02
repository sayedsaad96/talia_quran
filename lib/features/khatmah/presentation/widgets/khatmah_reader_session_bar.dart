import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../cubits/khatmah_cubit.dart';

class KhatmahReaderSessionBar extends StatelessWidget {
  const KhatmahReaderSessionBar({
    super.key,
    this.cubit,
    this.currentPage,
    this.onExit,
  });

  final KhatmahCubit? cubit;
  final int? currentPage;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    KhatmahCubit? resolvedCubit = cubit;
    if (resolvedCubit == null) {
      try {
        resolvedCubit = context.read<KhatmahCubit>();
      } catch (_) {
        resolvedCubit = null;
      }
    }

    if (resolvedCubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<KhatmahCubit, KhatmahState>(
      bloc: resolvedCubit,
      builder: (context, state) {
        if (state is! KhatmahActive) {
          return const SizedBox.shrink();
        }

        final plan = state.plan;
        final isArabic = context.isArabic;
        final isDark = context.isDark;
        final gold = isDark ? AppColors.primaryLight : AppColors.primary;
        final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

        final current = currentPage ?? plan.currentPage;
        final dailyTarget = plan.targetPagesPerDay;

        // Calculate progress within today's wird
        int wirdIndex;
        if (current < state.wirdStartPage) {
          wirdIndex = 1;
        } else if (current >= state.wirdEndPage) {
          wirdIndex = dailyTarget;
        } else {
          wirdIndex = (current - state.wirdStartPage + 1).clamp(1, dailyTarget);
        }

        final pageNumStr = isArabic
            ? MushafHizbHelper.toArabicNumber(current)
            : current.toString();
        final wirdIndexStr = isArabic
            ? MushafHizbHelper.toArabicNumber(wirdIndex)
            : wirdIndex.toString();
        final dailyTargetStr = isArabic
            ? MushafHizbHelper.toArabicNumber(dailyTarget)
            : dailyTarget.toString();

        final pageInfo = isArabic
            ? 'صفحة $pageNumStr ($wirdIndexStr من $dailyTargetStr من ورد اليوم)'
            : 'page $pageNumStr ($wirdIndexStr of $dailyTargetStr of today\'s wird)';

        final hasRecipient =
            plan.dedication.recipientName?.trim().isNotEmpty ?? false;
        final hasDedication = plan.dedication.isDedicated && hasRecipient;
        final recipient = plan.dedication.recipientName?.trim() ?? '';
        final dedicationPrefix = isArabic ? 'إهداء: ' : 'Dedicated to: ';
        final dedicationText =
            hasDedication ? '$dedicationPrefix$recipient' : null;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(
              color: gold.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 16,
                color: gold,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              color: gold,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (dedicationText != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dedicationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: gold.withValues(alpha: 0.8),
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pageInfo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? Colors.white70
                            : AppColors.lightTextSecondary,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton.icon(
                onPressed: onExit ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                icon: Icon(
                  Icons.exit_to_app_rounded,
                  size: 14,
                  color: gold,
                ),
                label: Text(
                  isArabic ? 'حفظ وخروج' : 'Save & exit',
                  style: AppTypography.labelSmall.copyWith(
                    color: gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
