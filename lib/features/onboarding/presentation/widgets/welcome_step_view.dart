import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_cta.dart';

/// Step 1 — the horizon. The golden mihrab sanctuary fills the sky above;
/// beneath it sit the name, one promise line, and the single call to climb.
/// Everything else about Talia is proven later by the living previews at
/// the fork, not listed here.
class WelcomeStepView extends StatelessWidget {
  const WelcomeStepView({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The sky gap lets the mihrab scene breathe; it yields first when
        // large text scales need the space, and the page scrolls if needed.
        final skyGap = (constraints.maxHeight * 0.40).clamp(120.0, 440.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.xs,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              // Basmala — free-floating in the sky above the sanctuary.
              JourneyEntrance(
                child: Text(
                  '﷽',
                  style: AppTypography.titleLarge.copyWith(
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.goldLight,
                    shadows: [
                      Shadow(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: skyGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scrim guarantees moon-ink contrast over any art crop.
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.darkBackground],
                        stops: [0.0, 0.5],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Center(
                        child: Image.asset(
                          'assets/images/logo_new_padded.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.onboardingWelcomeTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.displaySmall.copyWith(
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w800,
                            fontSize: context.isArabic ? 30 : 26,
                            color: AppColors.darkTextPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          context.l10n.onboardingWelcomeSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.darkTextSecondary,
                            height: 1.7,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  JourneyEntrance(
                    delayMs: 240,
                    child: OnboardingPrimaryCta(
                      label: context.l10n.onboardingStartJourney,
                      onTap: onStart,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
