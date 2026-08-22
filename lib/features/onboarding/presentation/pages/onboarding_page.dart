// ─── DIRECTION CONTRACT ──────────────────────────────────────────────────────
// THESIS: Talia's onboarding is a night journey that forks — the visitor
//   climbs one path of light and chooses a destination — refusing the
//   category's illustrated-slides default.
// OWN-WORLD: a committed deep-teal night (#021210→#041D1A) in both app
//   themes, gold reserved for spiritual emphasis (basmala, path, stars,
//   child journey), Amiri display over Noto Naskh moon-ink text; components
//   ride the app tokens (radiusLg controls, radiusXl destination shrines,
//   56px CTAs).
// STORY: the visitor feels Talia's calm reverence in one viewport, trusts
//   the app with themselves or a child, picks the lit path, and enters as
//   a guest in under 20 seconds — no teaching, no wall.
// FIRST VIEWPORT: full-bleed night horizon; the golden mihrab sanctuary
//   fills the upper half under a floating Amiri basmala; logo, one promise
//   line, and a single teal-gradient CTA anchor the bottom above the path
//   of light.
// FORM: «الرحلة الليلية المتفرّعة» (The Night Journey Fork), candidate 3 of 7,
//   seed key 6051da8b — concept-seed, scope surface, mode persuade.
// FINISH: unreviewed and undocumented is unfinished; this build ends with
//   the finish review, the verdict, and DESIGN.md.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/onboarding_cubit.dart';
import '../widgets/experience_fork_view.dart';
import '../widgets/onboarding_night_scene.dart';
import '../widgets/welcome_step_view.dart';

/// The Night Journey — a two-step first-run flow on a committed night
/// ground:
/// 1. The Horizon: welcome beneath the golden mihrab sanctuary.
/// 2. The Fork: choose the adult sanctuary or the child journey, then enter.
///
/// Cubit behavior, persisted keys, and destinations are unchanged from the
/// incumbent flow; only the world the visitor walks through is new.
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
  void initState() {
    super.initState();
    _pageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double get _page =>
      _pageController.hasClients && _pageController.position.hasContentDimensions
      ? _pageController.page ?? 0
      : 0;

  void _goToStep(int step) {
    context.read<OnboardingCubit>().goToStep(step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;

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
          // The journey begins at night regardless of the app theme.
          backgroundColor: AppColors.darkBackground,
          body: Stack(
            fit: StackFit.expand,
            children: [
              OnboardingNightScene(page: page),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      children: [
                        _JourneyTopBar(
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
                              WelcomeStepView(onStart: () => _goToStep(1)),
                              ExperienceForkView(state: state),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _JourneyTopBar extends StatelessWidget {
  const _JourneyTopBar({
    required this.currentStep,
    required this.onBack,
    required this.onSkip,
  });

  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    const subTextColor = AppColors.darkTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: onBack == null
                  ? const SizedBox.shrink()
                  : IconButton(
                      onPressed: onBack,
                      tooltip: context.l10n.previous,
                      icon: Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                        size: 20,
                        color: subTextColor,
                      ),
                    ),
            ),
            Expanded(child: _JourneyProgress(currentStep: currentStep)),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: subTextColor,
                  disabledForegroundColor: subTextColor.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Two waypoints of the journey — the horizon and the fork — joined by a
/// path that fills with gold as the visitor climbs.
class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 84,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(OnboardingState.stepCount, (index) {
            final isActive = index <= currentStep;
            final isCurrent = index == currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: isCurrent ? 4 : 3,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.goldLight : AppColors.darkDivider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
