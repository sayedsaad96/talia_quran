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
        if (state is KhatmahPaused) {
          return _statusBar(
            context,
            context.l10n.khatmahIsPaused,
            Icons.pause_circle_outline_rounded,
          );
        }
        if (state is KhatmahProgressFailure) {
          return _statusBar(
            context,
            context.l10n.khatmahProgressNotSaved,
            Icons.error_outline_rounded,
            onRetry: resolvedCubit!.retryLastProgress,
          );
        }
        final plan = switch (state) {
          final KhatmahActive active => active.plan,
          final KhatmahWirdCompleted completed => completed.plan,
          _ => null,
        };
        if (plan == null) return const SizedBox.shrink();
        final isArabic = context.isArabic;
        final isDark = context.isDark;
        final gold = isDark ? AppColors.primaryLight : AppColors.primary;
        final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

        final current = plan.currentPage;
        final target = state is KhatmahActive
            ? (startPage: state.wirdStartPage, endPage: state.wirdEndPage)
            : plan.dailyTargetFor(resolvedCubit!.displayDate);
        final dailyTarget = target.endPage - target.startPage + 1;
        final wirdIndex = plan.completedPages
            .where((page) => page >= target.startPage && page <= target.endPage)
            .length;

        final pageNumStr = isArabic
            ? MushafHizbHelper.toArabicNumber(current)
            : current.toString();
        final wirdIndexStr = isArabic
            ? MushafHizbHelper.toArabicNumber(wirdIndex)
            : wirdIndex.toString();
        final dailyTargetStr = isArabic
            ? MushafHizbHelper.toArabicNumber(dailyTarget)
            : dailyTarget.toString();

        final pageInfo = context.l10n.khatmahPageOfOfTodaySWird(
          (pageNumStr).toString(),
          (wirdIndexStr).toString(),
          (dailyTargetStr).toString(),
        );

        final hasRecipient =
            plan.dedication.recipientName?.trim().isNotEmpty ?? false;
        final hasDedication = plan.dedication.isDedicated && hasRecipient;
        final recipient = plan.dedication.recipientName?.trim() ?? '';
        final dedicationText = hasDedication
            ? context.l10n.khatmahDedicatedTo(recipient)
            : null;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: Border.all(color: gold.withValues(alpha: 0.28), width: 1),
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
              Icon(Icons.auto_stories_rounded, size: 16, color: gold),
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
              Flexible(
                child: TextButton.icon(
                  onPressed:
                      onExit ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                  icon: Icon(Icons.exit_to_app_rounded, size: 14, color: gold),
                  label: Text(
                    context.l10n.khatmahSaveExit,
                    style: AppTypography.labelSmall.copyWith(
                      color: gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBar(
    BuildContext context,
    String message,
    IconData icon, {
    VoidCallback? onRetry,
  }) {
    final isDark = context.isDark;
    final color = isDark ? AppColors.primaryLight : AppColors.primary;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: AppTypography.bodySmall)),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.khatmahRetry),
              ),
          ],
        ),
      ),
    );
  }
}
