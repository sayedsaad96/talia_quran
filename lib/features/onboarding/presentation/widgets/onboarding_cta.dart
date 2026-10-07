import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/icons/talia_icons.dart';
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
                      const Icon(
                        TaliaIcons.arrowForward,
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
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate()
        .fadeIn(duration: 380.ms, delay: delayMs.ms)
        .slideY(begin: slide, duration: 380.ms, delay: delayMs.ms);
  }
}

/// Responsive layout metrics for an onboarding slide based on viewport height.
class JourneySlideMetrics {
  final double topPadding;
  final double bottomPadding;
  final double badgeToTitle;
  final double titleToSubtitle;
  final double headerToBento;
  final double cardSpacing;
  final double secondaryCardHeight;
  final EdgeInsets heroPadding;
  final EdgeInsets secondaryCardPadding;

  const JourneySlideMetrics({
    required this.topPadding,
    required this.bottomPadding,
    required this.badgeToTitle,
    required this.titleToSubtitle,
    required this.headerToBento,
    required this.cardSpacing,
    required this.secondaryCardHeight,
    required this.heroPadding,
    required this.secondaryCardPadding,
  });

  factory JourneySlideMetrics.fromHeight(double height) {
    if (height < 580) {
      // Compact phones / landscape (< 580px)
      return const JourneySlideMetrics(
        topPadding: 10,
        bottomPadding: 10,
        badgeToTitle: 8,
        titleToSubtitle: 6,
        headerToBento: 14,
        cardSpacing: 10,
        secondaryCardHeight: 126,
        heroPadding: EdgeInsets.all(12),
        secondaryCardPadding: EdgeInsets.all(10),
      );
    } else if (height < 680) {
      // Standard phones (580px - 680px)
      return const JourneySlideMetrics(
        topPadding: 16,
        bottomPadding: 14,
        badgeToTitle: 10,
        titleToSubtitle: 8,
        headerToBento: 20,
        cardSpacing: 12,
        secondaryCardHeight: 136,
        heroPadding: EdgeInsets.all(AppSpacing.md),
        secondaryCardPadding: EdgeInsets.all(12),
      );
    } else if (height < 780) {
      // Tall phones (680px - 780px, e.g. Samsung Galaxy S22 Ultra)
      return const JourneySlideMetrics(
        topPadding: 24,
        bottomPadding: 20,
        badgeToTitle: 12,
        titleToSubtitle: 10,
        headerToBento: 26,
        cardSpacing: 14,
        secondaryCardHeight: 146,
        heroPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 18,
        ),
        secondaryCardPadding: EdgeInsets.all(14),
      );
    } else {
      // Extra tall devices (>= 780px)
      return const JourneySlideMetrics(
        topPadding: 32,
        bottomPadding: 26,
        badgeToTitle: 14,
        titleToSubtitle: 12,
        headerToBento: 30,
        cardSpacing: 16,
        secondaryCardHeight: 154,
        heroPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 20,
        ),
        secondaryCardPadding: EdgeInsets.all(16),
      );
    }
  }
}

/// Scrollable, adaptive body of a feature slide. Adapts padding, inter-widget
/// spacing, and bento card dimensions to the available viewport height so
/// content breathes naturally across all device sizes without excessive voids.
class JourneySlide extends StatelessWidget {
  const JourneySlide({super.key, this.children, this.builder})
    : assert(
        children != null || builder != null,
        'Either children or builder must be provided',
      );

  final List<Widget>? children;
  final Widget Function(BuildContext context, JourneySlideMetrics metrics)?
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final metrics = JourneySlideMetrics.fromHeight(height);

        final Widget content;
        if (builder != null) {
          content = builder!(context, metrics);
        } else {
          content = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children!,
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: metrics.topPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (height - metrics.topPadding - metrics.bottomPadding)
                  .clamp(0.0, double.infinity),
            ),
            child: content,
          ),
        );
      },
    );
  }
}
