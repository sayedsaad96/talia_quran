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
      duration: const Duration(milliseconds: 280),
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
        );
      },
    );
  }
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
        0,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? const SizedBox.shrink()
                : IconButton(
                    onPressed: onBack,
                    icon: Icon(
                      context.isArabic
                          ? Icons.arrow_forward_rounded
                          : Icons.arrow_back_rounded,
                    ),
                    color: subTextColor,
                  ),
          ),
          Expanded(child: _StepIndicator(currentStep: currentStep)),
          TextButton(
            onPressed: onSkip,
            child: Text(context.l10n.onboardingSkip),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final primary = context.isDark ? AppColors.primaryLight : AppColors.primary;
    final inactive = context.isDark
        ? AppColors.darkDivider
        : AppColors.lightDivider;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(OnboardingState.stepCount, (index) {
        final isActive = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? primary : inactive,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
      return const SizedBox(height: AppSpacing.lg);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.lg,
      ),
      child: FilledButton.icon(
        onPressed: state.isLoading ? null : onNext,
        icon: Icon(
          context.isArabic
              ? Icons.arrow_back_rounded
              : Icons.arrow_forward_rounded,
        ),
        label: Text(context.l10n.next),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

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
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
                width: 86,
                height: 86,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: primary.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: primary, size: 42),
              )
              .animate()
              .fadeIn(duration: 240.ms)
              .scale(begin: const Offset(.92, .92)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineMedium.copyWith(
              color: textColor,
              fontFamily: context.isArabic ? 'Amiri' : null,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: subTextColor,
              height: 1.5,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: AppSpacing.xl),
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
    return _StepScaffold(
      icon: Icons.auto_stories_rounded,
      title: context.l10n.onboardingWelcomeTitle,
      subtitle: context.l10n.onboardingWelcomeSubtitle,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FeaturePill(
              icon: Icons.menu_book_rounded,
              label: context.l10n.splashFeatureRead,
            ),
            _FeaturePill(
              icon: Icons.psychology_alt_rounded,
              label: context.l10n.splashFeatureMemorize,
            ),
            _FeaturePill(
              icon: Icons.rate_review_rounded,
              label: context.l10n.splashFeatureReview,
            ),
            _FeaturePill(
              icon: Icons.workspace_premium_rounded,
              label: context.l10n.splashFeatureGrow,
            ),
          ],
        ),
      ],
    );
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
              onTap: () => context.read<OnboardingCubit>().selectUserType(
                OnboardingUserType.adult,
              ),
            ),
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
            ),
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
                ),
                _GoalOption(
                  goal: OnboardingGoal.memorization,
                  icon: Icons.stars_rounded,
                  title: context.l10n.onboardingGoalKidsRewards,
                  description: context.l10n.onboardingGoalKidsRewardsDesc,
                ),
              ]
            : [
                _GoalOption(
                  goal: OnboardingGoal.reading,
                  icon: Icons.menu_book_rounded,
                  title: context.l10n.onboardingGoalDailyReading,
                  description: context.l10n.onboardingGoalDailyReadingDesc,
                ),
                _GoalOption(
                  goal: OnboardingGoal.memorization,
                  icon: Icons.psychology_alt_rounded,
                  title: context.l10n.onboardingGoalMemorization,
                  description: context.l10n.onboardingGoalMemorizationDesc,
                ),
                _GoalOption(
                  goal: OnboardingGoal.smartReview,
                  icon: Icons.rate_review_rounded,
                  title: context.l10n.onboardingGoalSmartReview,
                  description: context.l10n.onboardingGoalSmartReviewDesc,
                ),
                _GoalOption(
                  goal: OnboardingGoal.azkar,
                  icon: Icons.volunteer_activism_rounded,
                  title: context.l10n.onboardingGoalAzkar,
                  description: context.l10n.onboardingGoalAzkarDesc,
                ),
              ];

        return _StepScaffold(
          icon: Icons.explore_rounded,
          title: context.l10n.onboardingMainGoalTitle,
          subtitle: context.l10n.onboardingMainGoalSubtitle,
          children: [
            for (final option in goals) ...[
              _SelectableCard(
                selected: state.selectedGoal == option.goal,
                icon: option.icon,
                title: option.title,
                description: option.description,
                onTap: () =>
                    context.read<OnboardingCubit>().selectGoal(option.goal),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (state.selectedGoal == OnboardingGoal.smartReview) ...[
              const SizedBox(height: AppSpacing.sm),
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
                ),
                _FeatureHighlight(
                  Icons.workspace_premium_rounded,
                  context.l10n.onboardingFeatureProgressCertificates,
                  context.l10n.onboardingFeatureProgressCertificatesDesc,
                ),
                _FeatureHighlight(
                  Icons.family_restroom_rounded,
                  context.l10n.onboardingFeatureGuardian,
                  context.l10n.onboardingFeatureGuardianDesc,
                ),
                _FeatureHighlight(
                  Icons.menu_book_rounded,
                  context.l10n.onboardingFeatureQuranReader,
                  context.l10n.onboardingFeatureQuranReaderDesc,
                ),
              ]
            : [
                _FeatureHighlight(
                  Icons.menu_book_rounded,
                  context.l10n.onboardingFeatureQuranReader,
                  context.l10n.onboardingFeatureQuranReaderDesc,
                ),
                _FeatureHighlight(
                  Icons.psychology_alt_rounded,
                  context.l10n.onboardingFeatureMemorizationPlus,
                  context.l10n.onboardingFeatureMemorizationPlusDesc,
                ),
                _FeatureHighlight(
                  Icons.workspace_premium_rounded,
                  context.l10n.onboardingFeatureProgressCertificates,
                  context.l10n.onboardingFeatureProgressCertificatesDesc,
                ),
                _FeatureHighlight(
                  Icons.volunteer_activism_rounded,
                  context.l10n.onboardingFeatureAzkar,
                  context.l10n.onboardingFeatureAzkarDesc,
                ),
              ];

        return _StepScaffold(
          icon: Icons.dashboard_customize_rounded,
          title: context.l10n.onboardingHighlightsTitle,
          subtitle: state.isChild
              ? context.l10n.onboardingHighlightsChildSubtitle
              : context.l10n.onboardingHighlightsAdultSubtitle,
          children: [
            for (final highlight in highlights) ...[
              _HighlightTile(highlight: highlight),
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
        return _StepScaffold(
          icon: Icons.check_circle_outline_rounded,
          title: context.l10n.onboardingFinalTitle,
          subtitle: context.l10n.onboardingFinalSubtitle,
          children: [
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
            FilledButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () => context.read<OnboardingCubit>().continueAsGuest(),
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_outline_rounded),
              label: Text(context.l10n.onboardingContinueAsGuest),
              style: FilledButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  AppSpacing.buttonHeight,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () =>
                        context.read<OnboardingCubit>().signInOrCreateAccount(),
              icon: const Icon(Icons.login_rounded),
              label: Text(context.l10n.onboardingSignInCreate),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(
                  double.infinity,
                  AppSpacing.buttonHeight,
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: state.isChild
                ? Icons.child_care_rounded
                : Icons.person_outline_rounded,
            label: context.l10n.onboardingSummaryUserType,
            value: _userTypeLabel(context, state.selectedUserType),
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            icon: Icons.flag_rounded,
            label: context.l10n.onboardingSummaryGoal,
            value: _goalLabel(context, state.selectedGoal, state.isChild),
          ),
        ],
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final primary = context.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = context.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = context.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Row(
      children: [
        Icon(icon, color: primary, size: 24),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(color: subTextColor),
              ),
              Text(
                value,
                style: AppTypography.titleMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.16),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 24),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: subTextColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.check_circle_rounded, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.highlight});

  final _FeatureHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
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
        border: Border.all(color: primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(highlight.icon, color: primary, size: 26),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: AppTypography.titleSmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  highlight.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: subTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = context.isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  const _GoalOption({
    required this.goal,
    required this.icon,
    required this.title,
    required this.description,
  });

  final OnboardingGoal goal;
  final IconData icon;
  final String title;
  final String description;
}

class _FeatureHighlight {
  const _FeatureHighlight(this.icon, this.title, this.description);

  final IconData icon;
  final String title;
  final String description;
}
