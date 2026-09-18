import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_cta.dart';

/// Slide 2 — The Smart Memorization Bento View.
/// Highlights intelligent spaced repetition, mastery tracking, and active recall.
class OnboardingMemorizeBentoView extends StatelessWidget {
  const OnboardingMemorizeBentoView({super.key});

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
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.psychology_rounded,
                      size: 15,
                      color: AppColors.goldLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.onboardingPillarMemorizeTitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.goldLight,
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
              l10n.onboardingSlide2Title,
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
              l10n.onboardingSlide2Subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkTextSecondary,
                height: 1.55,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bento Card 1: Hero Mastery & Retention Window
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
                  color: AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.12),
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
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.goldLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.onboardingBentoMasteryTitle,
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
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          l10n.onboardingBentoMasteryValue,
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Progress Bar Breakdown (Spaced Repetition Status)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: SizedBox(
                      height: 10,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 75,
                            child: Container(color: const Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 18,
                            child: Container(color: AppColors.goldLight),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 7,
                            child: Container(color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Legend items
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statusDot(const Color(0xFF10B981), context.isArabic ? 'متقن راسخ' : 'Mastered'),
                      _statusDot(AppColors.goldLight, context.isArabic ? 'مراجعة قريبة' : 'Due Soon'),
                      _statusDot(AppColors.primaryLight, context.isArabic ? 'جديد' : 'New'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bento Row: 2 Secondary Cards (Active Recall + Spaced Interval)
          JourneyEntrance(
            delayMs: 270,
            child: Row(
              children: [
                // Card A: Active Recall (إخفاء الكلمات)
                Expanded(
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.visibility_off_rounded,
                                size: 16,
                                color: Color(0xFF3BD6BC),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'مَالِكِ [ ... ] الدِّينِ',
                                style: AppTypography.labelSmall.copyWith(
                                  fontFamily: 'Amiri',
                                  color: const Color(0xFF3BD6BC),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.onboardingBentoActiveRecallTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.onboardingBentoActiveRecallDesc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.darkTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Card B: Smart Review Schedule (المراجعة الذكية)
                Expanded(
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.update_rounded,
                                size: 16,
                                color: AppColors.goldLight,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                context.isArabic ? 'تذكير ذكي' : 'Smart Alert',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.goldLight,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.onboardingBentoReviewScheduleTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.onboardingBentoReviewScheduleDesc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.darkTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _statusDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.darkTextSecondary,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
