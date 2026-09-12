import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../streak/presentation/cubits/streak_cubit.dart';
import '../cubits/home_cubit.dart';

class HomeMomentumStrip extends StatelessWidget {
  const HomeMomentumStrip({super.key, required this.state, required this.isDark});

  final HomeLoaded state;
  final bool isDark;

  static String _levelTitle(BuildContext context, HomeLoaded state) {
    Achievement? best;
    for (final a in state.progress.achievements) {
      if (a.isUnlocked) {
        if (best == null || a.targetValue > best.targetValue) {
          best = a;
        }
      }
    }
    if (best == null) return context.l10n.levelBeginner;
    return context.localizedAchievementTitle(best);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    return BlocBuilder<StreakCubit, StreakState>(
      builder: (context, streakState) {
        final streak = streakState is StreakLoaded
            ? streakState.streak.currentStreak
            : state.progress.streakDays;
        final risk = state.streakRisk;
        final atRisk = risk?.isAtRisk == true;
        return Semantics(
          label: context.l10n.streakTerm,
          child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: atRisk
                      ? AppColors.warning.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        atRisk
                            ? Icons.warning_amber_rounded
                            : Icons.local_fire_department_rounded,
                        color: atRisk
                            ? AppColors.warning
                            : AppColors.streakOrange,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Only the label lives in the flex row so it always
                      // gets the full remaining width — the stats below are
                      // laid out in a Wrap instead of squeezed into the same
                      // Row, which previously could force this label into a
                      // near-zero width on narrow phones or large text scale.
                      Expanded(
                        child: Text(
                          atRisk
                              ? context.l10n.homeStreakAtRisk
                              : context.l10n.streakTerm,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$streak',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.streakOrange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${state.totalXp} ${context.l10n.xpLabel}',
                        style: AppTypography.labelSmall.copyWith(
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          _levelTitle(context, state),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if ((risk?.freezesAvailable ?? 0) > 0)
                        Text(
                          context.l10n.homeFreezesAvailable(
                            risk!.freezesAvailable,
                          ),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _WeekDots(
                    countsByDay: state.activityCountsByDay,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          );
        },
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.countsByDay, required this.isDark});
  final Map<String, int> countsByDay;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Row(
      children: [
        for (var i = 6; i >= 0; i--)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Builder(
                builder: (context) {
                  final day = today.subtract(Duration(days: i));
                  final key =
                      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final count = countsByDay[key] ?? 0;
                  return Column(
                    children: [
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: count > 0
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
