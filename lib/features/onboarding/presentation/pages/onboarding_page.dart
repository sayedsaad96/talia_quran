import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../cubits/onboarding_cubit.dart';

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
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
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
            child: Stack(
              children: [
                // Ambient Radial Background Glow based on current step
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: KeyedSubtree(
                      key: ValueKey<int>(state.currentStep),
                      child: CustomPaint(
                        painter: _AmbientGlowPainter(
                          step: state.currentStep,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ),
                // Main Content Column
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        _TopBar(
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
                            children: const [
                              _WelcomeStep(),
                              _UserTypeStep(),
                              _GoalStep(),
                              _FeatureHighlightsStep(),
                              _FinalSetupStep(),
                            ],
                          ),
                        ),
                        _BottomBar(
                          state: state,
                          onNext: () => _goToStep(state.currentStep + 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  _AmbientGlowPainter({required this.step, required this.isDark});

  final int step;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = switch (step) {
      0 => Offset(size.width * 0.5, size.height * 0.25),
      1 => Offset(size.width * 0.2, size.height * 0.4),
      2 => Offset(size.width * 0.8, size.height * 0.3),
      3 => Offset(size.width * 0.5, size.height * 0.5),
      _ => Offset(size.width * 0.5, size.height * 0.7),
    };

    final color = switch (step) {
      0 => AppColors.gold.withValues(alpha: isDark ? 0.08 : 0.05),
      1 => AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.07),
      2 => AppColors.gold.withValues(alpha: isDark ? 0.10 : 0.06),
      3 => AppColors.primaryLight.withValues(alpha: isDark ? 0.12 : 0.06),
      _ => AppColors.goldLight.withValues(alpha: isDark ? 0.10 : 0.05),
    };

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.75),
      );

    canvas.drawCircle(center, size.width * 0.75, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) =>
      oldDelegate.step != step || oldDelegate.isDark != isDark;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentStep,
    required this.onBack,
    required this.onSkip,
  });

  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final subTextColor = context.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: onBack == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: onBack,
                    icon: Icon(
                      context.isArabic
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                      size: 20,
                    ),
                    color: subTextColor,
                  ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _StepSegmentIndicator(currentStep: currentStep),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: subTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }
}

class _StepSegmentIndicator extends StatelessWidget {
  const _StepSegmentIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final activeColor = context.isDark ? AppColors.goldLight : AppColors.primary;
    final inactiveColor = context.isDark
        ? AppColors.darkDivider
        : AppColors.lightDivider;

    return Row(
      children: List.generate(OnboardingState.stepCount, (index) {
        final isCompleted = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: isCompleted
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.onNext});

  final OnboardingState state;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (state.currentStep == OnboardingState.stepCount - 1) {
      return const SizedBox(height: AppSpacing.sm);
    }

    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xs,
        AppSpacing.pagePadding,
        AppSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.primaryLight, AppColors.primary]
                : [AppColors.primary, AppColors.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? AppColors.primaryLight : AppColors.primary)
                  .withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: state.isLoading ? null : onNext,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Container(
              height: AppSpacing.buttonHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.next,
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
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.headerBadge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? headerBadge;

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
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xs),
          if (headerBadge != null) ...[
            Center(child: headerBadge),
            const SizedBox(height: AppSpacing.sm),
          ],
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glowing halo
                Container(
                  width: 106,
                  height: 106,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                ),
                // Inner icon circle
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [AppColors.primaryLight, AppColors.primary]
                          : [AppColors.primary, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 40),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: textColor,
              fontFamily: context.isArabic ? 'Amiri' : null,
              fontWeight: FontWeight.bold,
              fontSize: context.isArabic ? 24 : 22,
              height: 1.3,
            ),
          ).animate().fadeIn(duration: 320.ms, delay: 50.ms).slideY(begin: 0.06),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: subTextColor,
              height: 1.5,
              fontSize: 13.5,
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return _StepScaffold(
      icon: Icons.auto_stories_rounded,
      headerBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Text(
          '﷽',
          style: AppTypography.titleLarge.copyWith(
            color: context.isDark ? AppColors.goldLight : AppColors.goldDark,
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
      title: context.l10n.onboardingWelcomeTitle,
      subtitle: context.l10n.onboardingWelcomeSubtitle,
      children: [
        GridView.extent(
          maxCrossAxisExtent: 220,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.45,
          children: [
            _WelcomeFeatureCard(
              icon: Icons.menu_book_rounded,
              title: context.l10n.splashFeatureRead,
              subtitle: 'تلاوة صافية بمظهر المصحف',
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              delayMs: 150,
            ),
            _WelcomeFeatureCard(
              icon: Icons.psychology_alt_rounded,
              title: context.l10n.splashFeatureMemorize,
              subtitle: 'نظام حفظ ذكي ومخطط',
              color: AppColors.gold,
              delayMs: 200,
            ),
            _WelcomeFeatureCard(
              icon: Icons.rate_review_rounded,
              title: context.l10n.splashFeatureReview,
              subtitle: 'مراجعة وتثبيت المحفوظ',
              color: AppColors.info,
              delayMs: 250,
            ),
            _WelcomeFeatureCard(
              icon: Icons.workspace_premium_rounded,
              title: context.l10n.splashFeatureGrow,
              subtitle: 'شهادات وإنجازات موثقة',
              color: AppColors.success,
              delayMs: 300,
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeFeatureCard extends StatelessWidget {
  const _WelcomeFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.delayMs,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: delayMs.ms).slideY(begin: 0.08);
  }
}

class _UserTypeStep extends StatelessWidget {
  const _UserTypeStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return _StepScaffold(
          icon: Icons.person_search_rounded,
          title: context.l10n.onboardingUserTypeTitle,
          subtitle: context.l10n.onboardingUserTypeSubtitle,
          children: [
            _SelectableCard(
              selected: state.selectedUserType == OnboardingUserType.adult,
              icon: Icons.person_outline_rounded,
              title: context.l10n.onboardingUserTypeAdult,
              description: context.l10n.onboardingUserTypeAdultDesc,
              accent: context.isDark ? AppColors.primaryLight : AppColors.primary,
              onTap: () => context.read<OnboardingCubit>().selectUserType(
                OnboardingUserType.adult,
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 150.ms).slideY(begin: 0.05),
            const SizedBox(height: AppSpacing.md),
            _SelectableCard(
              selected: state.selectedUserType == OnboardingUserType.child,
              icon: Icons.child_care_rounded,
              title: context.l10n.onboardingUserTypeChild,
              description: context.l10n.onboardingUserTypeChildDesc,
              accent: AppColors.gold,
              onTap: () => context.read<OnboardingCubit>().selectUserType(
                OnboardingUserType.child,
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 220.ms).slideY(begin: 0.05),
          ],
        );
      },
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final goals = state.isChild
            ? [
                _GoalOption(
                  goal: OnboardingGoal.childJourney,
                  icon: Icons.route_rounded,
                  title: context.l10n.onboardingGoalKidsJourney,
                  description: context.l10n.onboardingGoalKidsJourneyDesc,
                  accent: AppColors.gold,
                ),
                _GoalOption(
                  goal: OnboardingGoal.memorization,
                  icon: Icons.stars_rounded,
                  title: context.l10n.onboardingGoalKidsRewards,
                  description: context.l10n.onboardingGoalKidsRewardsDesc,
                  accent: AppColors.kidsGreen,
                ),
              ]
            : [
                _GoalOption(
                  goal: OnboardingGoal.reading,
                  icon: Icons.menu_book_rounded,
                  title: context.l10n.onboardingGoalDailyReading,
                  description: context.l10n.onboardingGoalDailyReadingDesc,
                  accent: context.isDark ? AppColors.primaryLight : AppColors.primary,
                ),
                _GoalOption(
                  goal: OnboardingGoal.memorization,
                  icon: Icons.psychology_alt_rounded,
                  title: context.l10n.onboardingGoalMemorization,
                  description: context.l10n.onboardingGoalMemorizationDesc,
                  accent: AppColors.gold,
                ),
                _GoalOption(
                  goal: OnboardingGoal.smartReview,
                  icon: Icons.rate_review_rounded,
                  title: context.l10n.onboardingGoalSmartReview,
                  description: context.l10n.onboardingGoalSmartReviewDesc,
                  accent: AppColors.info,
                ),
                _GoalOption(
                  goal: OnboardingGoal.azkar,
                  icon: Icons.volunteer_activism_rounded,
                  title: context.l10n.onboardingGoalAzkar,
                  description: context.l10n.onboardingGoalAzkarDesc,
                  accent: AppColors.success,
                ),
              ];

        return _StepScaffold(
          icon: Icons.explore_rounded,
          title: context.l10n.onboardingMainGoalTitle,
          subtitle: context.l10n.onboardingMainGoalSubtitle,
          children: [
            for (int i = 0; i < goals.length; i++) ...[
              _SelectableCard(
                selected: state.selectedGoal == goals[i].goal,
                icon: goals[i].icon,
                title: goals[i].title,
                description: goals[i].description,
                accent: goals[i].accent,
                onTap: () =>
                    context.read<OnboardingCubit>().selectGoal(goals[i].goal),
              ).animate().fadeIn(duration: 280.ms, delay: (100 + i * 50).ms),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (state.selectedGoal == OnboardingGoal.smartReview) ...[
              const SizedBox(height: AppSpacing.xs),
              ErrorInfoBanner(
                type: ErrorInfoBannerType.info,
                title: context.l10n.onboardingSmartReviewNoteTitle,
                message: context.l10n.onboardingSmartReviewNoteDesc,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FeatureHighlightsStep extends StatelessWidget {
  const _FeatureHighlightsStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final highlights = state.isChild
            ? [
                _FeatureHighlight(
                  Icons.child_care_rounded,
                  context.l10n.onboardingFeatureKidsJourney,
                  context.l10n.onboardingFeatureKidsJourneyDesc,
                  AppColors.gold,
                ),
                _FeatureHighlight(
                  Icons.workspace_premium_rounded,
                  context.l10n.onboardingFeatureProgressCertificates,
                  context.l10n.onboardingFeatureProgressCertificatesDesc,
                  AppColors.success,
                ),
                _FeatureHighlight(
                  Icons.family_restroom_rounded,
                  context.l10n.onboardingFeatureGuardian,
                  context.l10n.onboardingFeatureGuardianDesc,
                  AppColors.info,
                ),
                _FeatureHighlight(
                  Icons.menu_book_rounded,
                  context.l10n.onboardingFeatureQuranReader,
                  context.l10n.onboardingFeatureQuranReaderDesc,
                  context.isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ]
            : [
                _FeatureHighlight(
                  Icons.menu_book_rounded,
                  context.l10n.onboardingFeatureQuranReader,
                  context.l10n.onboardingFeatureQuranReaderDesc,
                  context.isDark ? AppColors.primaryLight : AppColors.primary,
                ),
                _FeatureHighlight(
                  Icons.psychology_alt_rounded,
                  context.l10n.onboardingFeatureMemorizationPlus,
                  context.l10n.onboardingFeatureMemorizationPlusDesc,
                  AppColors.gold,
                ),
                _FeatureHighlight(
                  Icons.workspace_premium_rounded,
                  context.l10n.onboardingFeatureProgressCertificates,
                  context.l10n.onboardingFeatureProgressCertificatesDesc,
                  AppColors.amber,
                ),
                _FeatureHighlight(
                  Icons.volunteer_activism_rounded,
                  context.l10n.onboardingFeatureAzkar,
                  context.l10n.onboardingFeatureAzkarDesc,
                  AppColors.success,
                ),
              ];

        return _StepScaffold(
          icon: Icons.dashboard_customize_rounded,
          title: context.l10n.onboardingHighlightsTitle,
          subtitle: state.isChild
              ? context.l10n.onboardingHighlightsChildSubtitle
              : context.l10n.onboardingHighlightsAdultSubtitle,
          children: [
            for (int i = 0; i < highlights.length; i++) ...[
              _HighlightTile(
                highlight: highlights[i],
                index: i,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _FinalSetupStep extends StatelessWidget {
  const _FinalSetupStep();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        final isDark = context.isDark;

        return _StepScaffold(
          icon: Icons.check_circle_outline_rounded,
          title: context.l10n.onboardingFinalTitle,
          subtitle: context.l10n.onboardingFinalSubtitle,
          children: [
            _CommitmentSelector(
              selectedMinutes: state.dailyCommitmentMinutes,
              onSelect: (mins) => context.read<OnboardingCubit>().selectDailyCommitment(mins),
            ),
            const SizedBox(height: AppSpacing.md),
            _SummaryCard(state: state),
            if (state.isChild) ...[
              const SizedBox(height: AppSpacing.md),
              ErrorInfoBanner(
                type: ErrorInfoBannerType.info,
                title: context.l10n.onboardingGuardianNoteTitle,
                message: context.l10n.onboardingGuardianNoteDesc,
              ),
            ],
            if (state.status == OnboardingStatus.error &&
                state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              ErrorInfoBanner(
                type: ErrorInfoBannerType.error,
                title: context.l10n.errorOccurred,
                message: state.errorMessage!,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Guest CTA
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
                    color: (isDark ? AppColors.primaryLight : AppColors.primary)
                        .withValues(alpha: 0.3),
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
                          const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            context.l10n.onboardingContinueAsGuest,
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
            ),
            const SizedBox(height: AppSpacing.sm),
            // Sign in CTA
            OutlinedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () =>
                        context.read<OnboardingCubit>().signInOrCreateAccount(),
              icon: const Icon(Icons.login_rounded, size: 20),
              label: Text(
                context.l10n.onboardingSignInCreate,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  AppSpacing.buttonHeight,
                ),
                side: BorderSide(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: surface.withValues(alpha: isDark ? 0.85 : 0.95),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.primary)
                    .withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _SummaryRow(
                icon: state.isChild
                    ? Icons.child_care_rounded
                    : Icons.person_outline_rounded,
                label: context.l10n.onboardingSummaryUserType,
                value: _userTypeLabel(context, state.selectedUserType),
                accentColor: state.isChild ? AppColors.gold : AppColors.primary,
              ),
              const Divider(height: AppSpacing.md),
              _SummaryRow(
                icon: Icons.flag_rounded,
                label: context.l10n.onboardingSummaryGoal,
                value: _goalLabel(context, state.selectedGoal, state.isChild),
                accentColor: AppColors.gold,
              ),
              const Divider(height: AppSpacing.md),
              _SummaryRow(
                icon: Icons.timer_outlined,
                label: 'الالتزام اليومي',
                value: '${state.dailyCommitmentMinutes} دقيقة يومياً',
                accentColor: AppColors.info,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _userTypeLabel(BuildContext context, OnboardingUserType userType) {
    return userType == OnboardingUserType.child
        ? context.l10n.onboardingUserTypeChild
        : context.l10n.onboardingUserTypeAdult;
  }

  String _goalLabel(BuildContext context, OnboardingGoal goal, bool isChild) {
    return switch (goal) {
      OnboardingGoal.reading => context.l10n.onboardingGoalDailyReading,
      OnboardingGoal.memorization =>
        isChild
            ? context.l10n.onboardingGoalKidsRewards
            : context.l10n.onboardingGoalMemorization,
      OnboardingGoal.smartReview => context.l10n.onboardingGoalSmartReview,
      OnboardingGoal.azkar => context.l10n.onboardingGoalAzkar,
      OnboardingGoal.childJourney => context.l10n.onboardingGoalKidsJourney,
    };
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textColor = context.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = context.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: subTextColor,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.accent,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final color =
        accent ?? (isDark ? AppColors.primaryLight : AppColors.primary);
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
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
            color: selected ? color.withValues(alpha: isDark ? 0.18 : 0.08) : surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.16),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : color,
                  size: 24,
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
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: subTextColor,
                        height: 1.35,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check_circle_rounded, color: color, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.highlight, required this.index});

  final _FeatureHighlight highlight;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
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
        border: Border.all(color: highlight.color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: highlight.color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: highlight.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(highlight.icon, color: highlight.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  highlight.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: subTextColor,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms, delay: (100 + index * 50).ms).slideY(begin: 0.04);
  }
}

class _GoalOption {
  const _GoalOption({
    required this.goal,
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  final OnboardingGoal goal;
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
}

class _FeatureHighlight {
  const _FeatureHighlight(this.icon, this.title, this.description, this.color);

  final IconData icon;
  final String title;
  final String description;
  final Color color;
}

class _CommitmentSelector extends StatelessWidget {
  const _CommitmentSelector({
    required this.selectedMinutes,
    required this.onSelect,
  });

  final int selectedMinutes;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تحديد الالتزام اليومي',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'اختر الوقت المناسب لك يومياً لضبط خطتك الشخصية والتنبيهات',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _CommitmentOption(
              minutes: 5,
              title: '5 دقائق',
              subtitle: 'ورد ميسر',
              icon: Icons.bolt_rounded,
              selected: selectedMinutes == 5,
              onTap: () => onSelect(5),
            ),
            const SizedBox(width: AppSpacing.xs),
            _CommitmentOption(
              minutes: 15,
              title: '15 دقيقة',
              subtitle: 'ورد منتظم',
              icon: Icons.timer_outlined,
              selected: selectedMinutes == 15,
              onTap: () => onSelect(15),
            ),
            const SizedBox(width: AppSpacing.xs),
            _CommitmentOption(
              minutes: 30,
              title: '30 دقيقة',
              subtitle: 'ورد مكثف',
              icon: Icons.workspace_premium_rounded,
              selected: selectedMinutes == 30,
              onTap: () => onSelect(30),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommitmentOption extends StatelessWidget {
  const _CommitmentOption({
    required this.minutes,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.goldLight : AppColors.primary;
    final surface = selected
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.25)
            : AppColors.primary.withValues(alpha: 0.1))
        : (isDark ? AppColors.darkCard : AppColors.lightCard);
    final border = selected ? primary : (isDark ? AppColors.darkDivider : AppColors.lightDivider);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 6),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: border, width: selected ? 1.5 : 1.0),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: selected ? primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
