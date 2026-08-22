import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Shared 56px primary action of the journey — a teal gradient pillar with
/// a soft glow lift, mirroring the app's button-primary token on the
/// committed night ground.
class OnboardingPrimaryCta extends StatelessWidget {
  const OnboardingPrimaryCta({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.trailingArrow = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool trailingArrow;

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primaryLight;

    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              height: AppSpacing.buttonHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else ...[
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (trailingArrow) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet fade-and-rise entrance shared by journey content so motion stays
/// restrained outside the authored ascent.
class JourneyEntrance extends StatelessWidget {
  const JourneyEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.slide = 0.06,
  });

  final Widget child;
  final int delayMs;
  final double slide;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: 380.ms, delay: delayMs.ms)
        .slideY(begin: slide, duration: 380.ms, delay: delayMs.ms);
  }
}
