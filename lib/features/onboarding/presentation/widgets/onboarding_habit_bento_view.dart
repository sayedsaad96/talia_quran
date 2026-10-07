import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_cta.dart';
import 'onboarding_palette.dart';

/// Slide 3 — The Habit, Offline & Kids Bento View.
/// Highlights daily portion continuity, unbreakable streaks, 100% offline-first privacy,
/// and the playful kids journey with Talia.
class OnboardingHabitBentoView extends StatelessWidget {
  const OnboardingHabitBentoView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return JourneySlide(
      builder: (context, metrics) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
                      TaliaIcons.flame,
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
          SizedBox(height: metrics.badgeToTitle),

          // Title & Subtitle
          JourneyEntrance(
            delayMs: 90,
            child: Text(
              l10n.onboardingSlide3Title,
              textAlign: TextAlign.center,
              style: OnboardingStyles.titleBase(context).copyWith(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w800,
                color: AppColors.darkTextPrimary,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: metrics.titleToSubtitle),
          JourneyEntrance(
            delayMs: 140,
            child: Text(
              l10n.onboardingSlide3Subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkTextSecondary,
                height: 1.55,
              ),
            ),
          ),
          SizedBox(height: metrics.headerToBento),

          // Bento Card 1: Streak & Offline Assurance
          JourneyEntrance(
            delayMs: 200,
            child: Container(
              padding: metrics.heroPadding,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    OnboardingPalette.nightSurfaceVariant,
                    OnboardingPalette.nightSurface,
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
                              TaliaIcons.flame,
                              size: 17,
                              color: AppColors.streakOrange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.onboardingBentoStreakTitle,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
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
                            color: AppColors.streakOrange.withValues(
                              alpha: 0.4,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          l10n.onboardingBentoStreakDays,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.streakOrange,
                            fontWeight: FontWeight.bold,
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
                                  : OnboardingPalette.nightDivider,
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
                                  ? TaliaIcons.check
                                  : (isToday
                                        ? TaliaIcons.flame
                                        : TaliaIcons.circleFilled),
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
                      color: OnboardingPalette.emerald.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      border: Border.all(
                        color: OnboardingPalette.emerald.withValues(
                          alpha: 0.28,
                        ),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          TaliaIcons.cloudOff,
                          size: 14,
                          color: OnboardingPalette.emeraldText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.onboardingBentoOfflineBadge,
                          style: AppTypography.labelSmall.copyWith(
                            color: OnboardingPalette.emeraldText,
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
          SizedBox(height: metrics.cardSpacing),

          // Bento Card 2: Kids Journey Teaser with Talia Mascot
          JourneyEntrance(
            delayMs: 270,
            child: Container(
              height: (metrics.secondaryCardHeight - 8).clamp(128.0, 148.0),
              padding: metrics.secondaryCardPadding,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    OnboardingPalette.previewSurface,
                    OnboardingPalette.nightSurface,
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
                                  TaliaIcons.child,
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
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.darkTextPrimary,
                                    fontWeight: FontWeight.bold,
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
                                  TaliaIcons.starFilled,
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
