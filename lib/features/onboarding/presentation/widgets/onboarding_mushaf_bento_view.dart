import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_cta.dart';
import 'onboarding_palette.dart';
import 'onboarding_source_ayah.dart';

/// Slide 1 — The Mushaf Sanctuary Bento View.
/// Highlights authentic Mushaf reading, audio recitation, and easy tafsir.
class OnboardingMushafBentoView extends StatelessWidget {
  const OnboardingMushafBentoView({super.key});

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
                  color: AppColors.primaryLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 15,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.onboardingPillarReadTitle,
                      style: AppTypography.labelSmall.copyWith(
                        color: OnboardingPalette.nightTealText,
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
              l10n.onboardingSlide1Title,
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
              l10n.onboardingSlide1Subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkTextSecondary,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bento Card 1: Hero Mushaf Sanctuary Window
          JourneyEntrance(
            delayMs: 200,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.parchmentLight, AppColors.parchmentWarm],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: AppColors.desertSand.withValues(alpha: 0.7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Surah Header Ornament
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _decorativeLine(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.desertSand.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          border: Border.all(
                            color: AppColors.desertSand.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          l10n.onboardingBentoMushafSurah,
                          style: AppTypography.labelMedium.copyWith(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkDeep,
                          ),
                        ),
                      ),
                      _decorativeLine(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Ayah Text in Amiri
                  OnboardingSourceAyah(
                    surah: 1,
                    ayah: 1,
                    builder: (context, text) => Text(
                      text,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.inkDeep.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  OnboardingSourceAyah(
                    surah: 1,
                    ayah: 2,
                    // The ﴿٢﴾ end-of-ayah marker is UI numbering, not text.
                    builder: (context, text) => Text(
                      '$text ﴿٢﴾',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.w800,
                        fontSize: context.isArabic ? 22 : 18,
                        color: AppColors.inkDeep,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Tafsir badge inside Mushaf
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inkDeep.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    // Arabic shows the ayah itself, so it comes from the
                    // source; English shows the (localized) translation.
                    child: context.isArabic
                        ? OnboardingSourceAyah(
                            surah: 1,
                            ayah: 2,
                            builder: (context, text) => Text(
                              text,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.inkDeep.withValues(
                                  alpha: 0.75,
                                ),
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                          )
                        : Text(
                            l10n.onboardingBentoMushafAyah,
                            textAlign: TextAlign.center,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.inkDeep.withValues(alpha: 0.75),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bento Row: 2 Secondary Cards (Audio + Tafsir)
          JourneyEntrance(
            delayMs: 270,
            child: Row(
              children: [
                // Card A: Audio & Listening
                Expanded(
                  child: Container(
                    height: 132,
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.headphones_rounded,
                                size: 17,
                                color: OnboardingPalette.nightTealText,
                              ),
                            ),
                            // Mini audio wave simulation
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [4, 12, 18, 8, 14, 6]
                                  .map(
                                    (h) => Container(
                                      width: 2.5,
                                      height: h.toDouble(),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1.2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.onboardingBentoListeningTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.onboardingBentoListeningDesc,
                              maxLines: 1,
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

                // Card B: Tafsir & Word Meanings
                Expanded(
                  child: Container(
                    height: 132,
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 17,
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
                                'تفسير ميسر',
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
                              l10n.onboardingBentoTafsirTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.onboardingBentoTafsirDesc,
                              maxLines: 1,
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
      ),
    );
  }

  static Widget _decorativeLine() {
    return Expanded(
      child: Container(
        height: 0.8,
        color: AppColors.desertSand.withValues(alpha: 0.5),
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
