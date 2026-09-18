import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_cta.dart';

/// Slide 3 — The Habit, Offline & Kids Bento View.
/// Highlights daily portion continuity, unbreakable streaks, 100% offline-first privacy,
/// and the playful kids journey with Talia.
class OnboardingHabitBentoView extends StatelessWidget {
  const OnboardingHabitBentoView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          JourneyEntrance(
            delayMs: 40,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.streakOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: AppColors.streakOrange.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 15,
                      color: AppColors.streakOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.onboardingPillarHabitTitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.streakOrange,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Title & Subtitle
          JourneyEntrance(
            delayMs: 90,
            child: Text(
              l10n.onboardingSlide3Title,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w800,
                fontSize: context.isArabic ? 25 : 22,
                color: AppColors.darkTextPrimary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          JourneyEntrance(
            delayMs: 140,
            child: Text(
              l10n.onboardingSlide3Subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkTextSecondary,
                height: 1.55,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bento Card 1: Streak & Offline Assurance
          JourneyEntrance(
            delayMs: 200,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.darkSurfaceVariant,
                    AppColors.darkSurface,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: AppColors.streakOrange.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.streakOrange.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.streakOrange.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              size: 17,
                              color: AppColors.streakOrange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.onboardingBentoStreakTitle,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.streakOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: AppColors.streakOrange.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          l10n.onboardingBentoStreakDays,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.streakOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 7 Days Streak Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isDone = i < 6;
                      final isToday = i == 6;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone || isToday
                                  ? AppColors.streakOrange.withValues(
                                      alpha: isToday ? 0.95 : 0.22,
                                    )
                                  : AppColors.darkDivider,
                              border: Border.all(
                                color: isToday
                                    ? AppColors.goldLight
                                    : (isDone
                                        ? AppColors.streakOrange
                                        : Colors.transparent),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isDone
                                  ? Icons.check_rounded
                                  : (isToday
                                      ? Icons.local_fire_department_rounded
                                      : Icons.circle),
                              size: isDone ? 17 : (isToday ? 18 : 6),
                              color: isDone
                                  ? AppColors.streakOrange
                                  : (isToday
                                      ? Colors.white
                                      : AppColors.darkTextSecondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dayLabel(i, context.isArabic),
                            style: AppTypography.labelSmall.copyWith(
                              color: isToday
                                  ? AppColors.streakOrange
                                  : AppColors.darkTextSecondary,
                              fontSize: 10,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Offline assurance pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.28),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 14,
                          color: Color(0xFF34D399),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.onboardingBentoOfflineBadge,
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bento Card 2: Kids Journey Teaser with Talia Mascot
          JourneyEntrance(
            delayMs: 270,
            child: Container(
              height: 124,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0C2B27),
                    AppColors.darkSurface,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.18),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.child_care_rounded,
                                  size: 15,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l10n.onboardingBentoKidsTeaserTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.darkTextPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.onboardingBentoKidsTeaserDesc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.darkTextSecondary,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: List.generate(
                              3,
                              (_) => const Padding(
                                padding: EdgeInsetsDirectional.only(end: 3),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    child: SizedBox(
                      width: 90,
                      height: double.infinity,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withValues(alpha: 0.15),
                            ),
                            width: 76,
                            height: 76,
                          ),
                          Image.asset(
                            'assets/images/character/Talia_Master_Character.png',
                            height: 98,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  static String _dayLabel(int index, bool isArabic) {
    if (isArabic) {
      const days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
      return days[index];
    } else {
      const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      return days[index];
    }
  }
}
