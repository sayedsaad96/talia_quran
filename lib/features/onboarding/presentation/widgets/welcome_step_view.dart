import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'onboarding_cta.dart';

/// Step 1 — a single, responsive brand composition followed by the welcome
/// copy and the primary action. The hero owns all decorative branding so the
/// compact logo and basmala are not repeated below it.
class WelcomeStepView extends StatelessWidget {
  const WelcomeStepView({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reserve enough space for the copy and CTA, then let the hero use the
        // remaining room up to its natural square composition. Short screens
        // reduce the artwork first and scroll only when accessibility text
        // scaling needs more room.
        final contentReserve = context.isArabic ? 226.0 : 214.0;
        final maxHeroForViewport = math.max(
          240.0,
          constraints.maxHeight - contentReserve,
        );
        final heroHeight = math
            .min(constraints.maxWidth, maxHeroForViewport)
            .clamp(240.0, 520.0)
            .toDouble();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: heroHeight,
                width: double.infinity,
                child: const _WelcomeHeroArt(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
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
                    const SizedBox(height: AppSpacing.xl),
                    JourneyEntrance(
                      delayMs: 180,
                      child: OnboardingPrimaryCta(
                        label: context.l10n.onboardingStartJourney,
                        onTap: onStart,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeHeroArt extends StatelessWidget {
  const _WelcomeHeroArt();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: ShaderMask(
          // Melt only the bottom edge so the artwork stays integrated with
          // the night surface without visually bleeding into the copy.
          blendMode: BlendMode.dstOut,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.transparent, Colors.black],
            stops: [0.0, 0.86, 1.0],
          ).createShader(bounds),
          child: Image.asset(
            'assets/images/onboarding/splash_new.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
