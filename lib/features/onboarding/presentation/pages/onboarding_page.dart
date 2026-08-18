import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/onboarding_cubit.dart';

/// Streamlined, high-end editorial onboarding experience for Talia.
///
/// Follows a peaceful 2-step structure:
/// 1. Welcome & Identity (introducing Talia's Quranic pillars).
/// 2. Experience Selection (Adult vs Child with inline details) & immediate entry.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OnboardingCubit>(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    context.read<OnboardingCubit>().goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.completedRoute != current.completedRoute,
      listener: (context, state) {
        if (state.status == OnboardingStatus.completed &&
            state.completedRoute != null) {
          context.go(state.completedRoute!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  children: [
                    _OnboardingTopBar(
                      currentStep: state.currentStep,
                      onBack: state.currentStep == 0
                          ? null
                          : () => _goToStep(state.currentStep - 1),
                      onSkip: state.isLoading
                          ? null
                          : () => context.read<OnboardingCubit>().skip(),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: state.isLoading
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        onPageChanged: (step) =>
                            context.read<OnboardingCubit>().goToStep(step),
                        children: [
                          _WelcomeStepView(
                            onStart: () => _goToStep(1),
                          ),
                          _ExperienceSelectionStepView(
                            state: state,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({
    required this.currentStep,
    required this.onBack,
    required this.onSkip,
  });

  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xs,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            // Back Button
            SizedBox(
              width: 40,
              height: 40,
              child: onBack == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: onBack,
                      tooltip: context.l10n.previous,
                      icon: Icon(
                        context.isArabic
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                        size: 20,
                      ),
                      color: subTextColor,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Minimalist Segment Indicator
            Expanded(
              child: _StepIndicator(currentStep: currentStep),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Skip CTA
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: subTextColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.onboardingSkip,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: subTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.isDark ? AppColors.goldLight : AppColors.primary;
    final inactiveColor = context.isDark
        ? AppColors.darkDivider
        : AppColors.lightDivider;

    return Row(
      children: List.generate(OnboardingState.stepCount, (index) {
        final isCurrent = index == currentStep;
        final isCompleted = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: isCurrent ? 4 : 3,
            decoration: BoxDecoration(
              color: isCompleted ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ─── Step 1: Welcome & Identity ───────────────────────────────────────────────

class _WelcomeStepView extends StatelessWidget {
  const _WelcomeStepView({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xs,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Basmala Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                '﷽',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.goldLight : AppColors.goldDark,
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
          ),
          const SizedBox(height: AppSpacing.md),
          // Logo & Title
          Center(
            child: Image.asset(
              'assets/images/logo_new_padded.png',
              width: 72,
              height: 72,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.onboardingWelcomeTitle,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall.copyWith(
              color: textColor,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w800,
              fontSize: context.isArabic ? 28 : 24,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.08),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.onboardingWelcomeSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: subTextColor,
              height: 1.5,
              fontSize: 13.5,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: AppSpacing.lg),
          // 3 Core Pillars (Editorial Layout)
          _EditorialPillarTile(
            icon: Icons.menu_book_rounded,
            title: context.l10n.onboardingPillarReadTitle,
            description: context.l10n.onboardingPillarReadDesc,
            color: primary,
            delayMs: 250,
          ),
          const SizedBox(height: AppSpacing.sm),
          _EditorialPillarTile(
            icon: Icons.psychology_alt_rounded,
            title: context.l10n.onboardingPillarMemorizeTitle,
            description: context.l10n.onboardingPillarMemorizeDesc,
            color: AppColors.gold,
            delayMs: 320,
          ),
          const SizedBox(height: AppSpacing.sm),
          _EditorialPillarTile(
            icon: Icons.volunteer_activism_rounded,
            title: context.l10n.onboardingPillarHabitTitle,
            description: context.l10n.onboardingPillarHabitDesc,
            color: AppColors.success,
            delayMs: 390,
          ),
          const SizedBox(height: AppSpacing.xl),
          // Start Journey CTA
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.primaryLight, AppColors.primary]
                    : [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onStart,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  height: AppSpacing.buttonHeight,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.onboardingStartJourney,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        context.isArabic
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 450.ms).slideY(begin: 0.08),
        ],
      ),
    );
  }
}

class _EditorialPillarTile extends StatelessWidget {
  const _EditorialPillarTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.delayMs,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : color).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: subTextColor,
                    height: 1.4,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms, delay: delayMs.ms).slideY(begin: 0.05);
  }
}

// ─── Step 2: Experience Selection ─────────────────────────────────────────────

class _ExperienceSelectionStepView extends StatelessWidget {
  const _ExperienceSelectionStepView({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final isAdult = state.selectedUserType == OnboardingUserType.adult;
    final isChild = state.selectedUserType == OnboardingUserType.child;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xs,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Heading
          Text(
            context.l10n.onboardingChooseExpTitle,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: textColor,
              fontFamily: 'Amiri',
              fontWeight: FontWeight.w800,
              fontSize: context.isArabic ? 24 : 22,
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.onboardingChooseExpSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: subTextColor,
              height: 1.45,
              fontSize: 13,
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 50.ms),
          const SizedBox(height: AppSpacing.lg),

          // Option 1: Adult Journey Card
          _ExperienceCard(
            selected: isAdult,
            icon: Icons.person_outline_rounded,
            title: context.l10n.onboardingAdultPathTitle,
            subtitle: context.l10n.onboardingAdultPathSubtitle,
            accentColor: primary,
            onTap: () => context.read<OnboardingCubit>().selectUserType(
              OnboardingUserType.adult,
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 100.ms).slideY(begin: 0.04),

          const SizedBox(height: AppSpacing.md),

          // Option 2: Child Journey Card (with inline feature details)
          _ExperienceCard(
            selected: isChild,
            icon: Icons.child_care_rounded,
            title: context.l10n.onboardingKidsPathTitle,
            subtitle: context.l10n.onboardingKidsPathSubtitle,
            accentColor: AppColors.gold,
            onTap: () => context.read<OnboardingCubit>().selectUserType(
              OnboardingUserType.child,
            ),
            childPills: [
              context.l10n.onboardingKidsFeatureMissions,
              context.l10n.onboardingKidsFeatureAudio,
              context.l10n.onboardingKidsFeatureStars,
            ],
          ).animate().fadeIn(duration: 350.ms, delay: 180.ms).slideY(begin: 0.04),

          if (state.status == OnboardingStatus.error &&
              state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                state.errorMessage!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Primary CTA: Continue as guest
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.primaryLight, AppColors.primary]
                    : [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: state.isLoading
                    ? null
                    : () => context.read<OnboardingCubit>().continueAsGuest(),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Container(
                  height: AppSpacing.buttonHeight,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else ...[
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          context.l10n.onboardingEnterAsGuest,
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 250.ms),

          const SizedBox(height: AppSpacing.sm),

          // Secondary CTA: Sign in / Create Account
          OutlinedButton.icon(
            onPressed: state.isLoading
                ? null
                : () => context.read<OnboardingCubit>().signInOrCreateAccount(),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text(
              context.l10n.onboardingSignInAccount,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.goldLight : primary,
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              side: BorderSide(
                color: (isDark ? AppColors.goldLight : primary).withValues(alpha: 0.4),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.childPills,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final List<String>? childPills;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final defaultBorder = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(alpha: isDark ? 0.15 : 0.07)
                : surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? accentColor : defaultBorder,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? accentColor
                          : accentColor.withValues(alpha: isDark ? 0.16 : 0.10),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.white : accentColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: subTextColor,
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? accentColor : Colors.transparent,
                      border: Border.all(
                        color: selected ? accentColor : defaultBorder,
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
              if (childPills != null && childPills!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: childPills!.map((pill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        pill,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
