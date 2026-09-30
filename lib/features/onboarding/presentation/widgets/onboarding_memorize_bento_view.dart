import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_cta.dart';
import 'onboarding_palette.dart';
import 'onboarding_source_ayah.dart';

/// Slide 2 — The Smart Memorization Bento View.
/// Highlights intelligent spaced repetition, mastery tracking, and active recall.
class OnboardingMemorizeBentoView extends StatelessWidget {
  const OnboardingMemorizeBentoView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return JourneySlide(
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
            style: OnboardingStyles.titleBase(context).copyWith(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w800,
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
                  OnboardingPalette.nightSurfaceVariant,
                  OnboardingPalette.nightSurface,
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
                        color: OnboardingPalette.emerald.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                        border: Border.all(
                          color: OnboardingPalette.emerald.withValues(
                            alpha: 0.35,
                          ),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        l10n.onboardingBentoMasteryValue,
                        style: AppTypography.labelSmall.copyWith(
                          color: OnboardingPalette.emeraldText,
                          fontWeight: FontWeight.bold,
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
                          child: Container(color: OnboardingPalette.emerald),
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
                    _statusDot(
                      OnboardingPalette.emerald,
                      l10n.onboardingBentoStatusMastered,
                    ),
                    _statusDot(
                      AppColors.goldLight,
                      l10n.onboardingBentoStatusDueSoon,
                    ),
                    _statusDot(
                      AppColors.primaryLight,
                      l10n.onboardingBentoStatusNew,
                    ),
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
                    color: OnboardingPalette.nightSurface,
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
                              color: OnboardingPalette.nightTealText,
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
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusXs,
                              ),
                            ),
                            // First and last words verbatim from the
                            // source; the middle is hidden, as in the
                            // real word-hiding exercise.
                            child: OnboardingSourceAyah(
                              surah: 1,
                              ayah: 4,
                              builder: (context, text) {
                                final words = text.split(' ');
                                return Text(
                                  '${words.first} [ ... ] ${words.last}',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontFamily: 'Amiri',
                                    color: OnboardingPalette.nightTealText,
                                  ),
                                );
                              },
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
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.onboardingBentoActiveRecallDesc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.darkTextSecondary,
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
                    color: OnboardingPalette.nightSurface,
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
                              l10n.onboardingBentoSmartAlert,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.goldLight,
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
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.onboardingBentoReviewScheduleDesc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.darkTextSecondary,
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
          ),
        ),
      ],
    );
  }
}
