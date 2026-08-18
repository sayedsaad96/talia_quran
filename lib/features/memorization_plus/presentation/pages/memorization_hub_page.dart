import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/progress/progress_changed_reason.dart';
import '../../../../core/progress/progress_events_bus.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../cubits/memorization_identity_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../theme/kids_theme.dart';

class MemorizationHubPage extends StatefulWidget {
  const MemorizationHubPage({super.key});

  @override
  State<MemorizationHubPage> createState() => _MemorizationHubPageState();
}

class _MemorizationHubPageState extends State<MemorizationHubPage> {
  late Future<_HubLoadResult> _hubFuture;
  StreamSubscription<ProgressChangedReason>? _busSub;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _hubFuture = _loadHub();
    // Subscribe to progress bus so the Hub reloads when cloud pull, plan, review,
    // or kids progress changes — the IndexedStack keeps this page alive so
    // initState does not re-run on tab switch.
    _busSub = getIt<ProgressEventsBus>().changes.listen((reason) {
      if (!mounted) return;
      const refreshReasons = {
        ProgressChangedReason.dailyPlan,
        ProgressChangedReason.reviewRecord,
        ProgressChangedReason.kidsProgress,
        ProgressChangedReason.cloudPull,
      };
      if (refreshReasons.contains(reason)) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) _retryTargets();
        });
      }
    });
  }

  Future<_HubLoadResult> _loadHub() async {
    final repository = getIt<MemorizationPlusRepository>();
    final targets = await MemorizationNavigationResolver(repository).resolve();
    final planResult = await repository.getCachedDailyPlan();
    final plan = planResult.fold((_) => null, (value) => value);
    return _HubLoadResult(targets: targets, dailyPlan: plan);
  }

  void _retryTargets() {
    setState(() {
      _hubFuture = _loadHub();
    });
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  /// Resolves the adult destination fresh at tap-time so a newly saved plan is
  /// honoured even though this hub is kept alive inside the IndexedStack shell
  /// (its cached [_hubFuture] would otherwise still point at plan setup).
  Future<void> _openAdultTarget({required bool isReview}) async {
    final repository = getIt<MemorizationPlusRepository>();
    final targets = await MemorizationNavigationResolver(repository).resolve();
    if (!mounted) return;
    final route = isReview
        ? targets.reviewQuizLocation
        : targets.todayPlanLocation;
    await context.push(route);
    if (mounted) _retryTargets();
  }

  Future<void> _confirmPathSelection(
    BuildContext context, {
    required MemorizationPath path,
    required String title,
    required String description,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.memorizationPathConfirmTitle,
                style: AppTypography.headlineSmall.copyWith(
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.itemGap),
              Text(
                '$title\n$description',
                style: AppTypography.bodyMedium.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.itemGap),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.memorizationPathCanChangeLater,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.pagePadding),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(context.l10n.confirm),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(context.read<MemorizationIdentityCubit>().selectPath(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return BlocProvider(
      create: (context) => getIt<MemorizationIdentityCubit>(),
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: BlocConsumer<MemorizationIdentityCubit, MemorizationIdentityState>(
          listener: (context, state) {
            if (state is MemorizationIdentitySuccess) {
              final profile = state.profile;
              if (profile.isAdult) {
                _retryTargets();
              } else if (profile.isChild) {
                _retryTargets();
                final authState = context.read<AuthCubit>().state;
                context.push(
                  authState is AuthAuthenticated
                      ? AppRoutes.memorizationPlusGuardianLinking
                      : AppRoutes.memorizationPlusKidsHome,
                );
              }
            } else if (state is MemorizationIdentityError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final isSelectingPath = state is MemorizationIdentityLoading;
            return FutureBuilder<_HubLoadResult>(
              future: _hubFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: LoadingWidget());
                }
                if (snapshot.hasError) {
                  return ErrorStateWidget(
                    message: context.l10n.errorOccurred,
                    onRetry: _retryTargets,
                  );
                }
                return CustomScrollView(
                  slivers: [
                    _HubAppBar(isDark: isDark),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.lg,
                        AppSpacing.pagePadding,
                        120,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          _sectionsFor(
                            context,
                            snapshot.data?.targets,
                            snapshot.data?.dailyPlan,
                            isDark,
                            isSelectingPath,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sectionsFor(
    BuildContext context,
    MemorizationNavigationTargets? targets,
    DailyPlan? dailyPlan,
    bool isDark,
    bool isSelectingPath,
  ) {
    final profile = targets?.profile;
    if (profile?.isAdult == true) {
      return [
        _HubSectionHeader(
          title: context.l10n.dailyPlanHeaderTitle,
          subtitle: context.l10n.memorizationHubDailyPlanSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dailyPlan != null && dailyPlan.totalItems > 0)
          _HubDailyPlanSummaryCard(plan: dailyPlan, isDark: isDark),
        if (dailyPlan != null && dailyPlan.totalItems > 0)
          const SizedBox(height: AppSpacing.sm),
        if (dailyPlan?.isRequiredPlanCompleted != true)
          _HubActionCard.primary(
            icon: Icons.today_rounded,
            title: context.l10n.homeContinueTodaysPlan,
            description: context.l10n.memorizationHubContinuePlanDescription,
            onTap: () => _openAdultTarget(isReview: false),
            isDark: isDark,
          ),
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.checklist_rounded,
          title: context.l10n.memorizationHubViewPlanTitle,
          description: context.l10n.dailyPlanProgressCount(
            dailyPlan?.requiredCompletedCount ?? 0,
            dailyPlan?.totalItems ?? 0,
          ),
          route: AppRoutes.memorizationPlusDailyPlan,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.l10n.memorizationHubPracticeSectionTitle,
          subtitle: context.l10n.memorizationHubPracticeSectionSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.auto_stories_rounded,
          title: context.l10n.memorizationHubPracticeBySurahTitle,
          description: context.l10n.memorizationHubPracticeBySurahDescription,
          route: AppRoutes.hifzPracticeSurah,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.l10n.memorizationHubReviewSectionTitle,
          subtitle: context.l10n.memorizationHubReviewSectionSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.mic_rounded,
          title: context.l10n.reviewQuizTitle,
          description: context.l10n.memorizationHubReviewCardDescription,
          onTap: () => _openAdultTarget(isReview: true),
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.l10n.settings,
          subtitle: context.l10n.memorizationHubSettingsSectionSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.settings_suggest_rounded,
          title: context.l10n.memorizationHubPlanSettingsTitle,
          description: context.l10n.memorizationHubPlanSettingsDescription,
          route: AppRoutes.memorizationPlusCustomPlan,
          isDark: isDark,
        ),
      ];
    }

    if (profile?.isChild == true) {
      return [
        _HubSectionHeader(
          title: context.l10n.homeCurrentMission,
          subtitle: context.l10n.memorizationHubKidsMissionSectionSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KidsHubActionCard(
          icon: Icons.flag_rounded,
          title: context.l10n.homeCurrentMission,
          description: context.l10n.memorizationHubKidsMissionCardDescription,
          route: AppRoutes.memorizationPlusKidsHome,
          variant: _KidsCardVariant.mission,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.l10n.memorizationHubKidsJourneyTitle,
          subtitle: context.l10n.memorizationHubKidsJourneySubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KidsHubActionCard(
          icon: Icons.map_rounded,
          title: context.l10n.memorizationHubKidsJourneyTitle,
          description: context.l10n.memorizationHubKidsJourneyDescription,
          route: targets!.kidsJourneyLocation,
          variant: _KidsCardVariant.journey,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.l10n.memorizationHubKidsRewardsTitle,
          subtitle: context.l10n.memorizationHubKidsRewardsSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KidsHubActionCard(
          icon: Icons.stars_rounded,
          title: context.l10n.memorizationHubKidsRewardsTitle,
          description: context.l10n.memorizationHubKidsRewardsDescription,
          route: AppRoutes.progress,
          variant: _KidsCardVariant.rewards,
        ),
      ];
    }

    return [
      Text(
        context.l10n.memorizationPathQuestion,
        style: AppTypography.headlineMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        context.l10n.memorizationPathDescription,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.xxl),
      _UnifiedPathChoiceCard(
        title: context.l10n.memorizationPathAdultsTitle,
        description: context.l10n.memorizationPathAdultsDesc,
        icon: Icons.person_outline,
        color: AppColors.primary,
        isLoading: isSelectingPath,
        onTap: () {
          _confirmPathSelection(
            context,
            path: MemorizationPath.adult,
            title: context.l10n.memorizationPathAdultsTitle,
            description: context.l10n.memorizationPathAdultsDesc,
          );
        },
      ),
      const SizedBox(height: AppSpacing.lg),
      _UnifiedPathChoiceCard(
        title: context.l10n.memorizationPathKidsTitle,
        description: context.l10n.memorizationPathKidsDesc,
        icon: Icons.child_care,
        color: AppColors.gold,
        isLoading: isSelectingPath,
        onTap: () {
          _confirmPathSelection(
            context,
            path: MemorizationPath.child,
            title: context.l10n.memorizationPathKidsTitle,
            description: context.l10n.memorizationPathKidsDesc,
          );
        },
      ),
    ];
  }
}

class _HubAppBar extends StatelessWidget {
  const _HubAppBar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A2A22), Color(0xFF0D1117)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.accentBlue],
                  ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.memorization,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.memorizationHubHeaderSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
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

class _HubLoadResult {
  const _HubLoadResult({required this.targets, this.dailyPlan});

  final MemorizationNavigationTargets targets;
  final DailyPlan? dailyPlan;
}

class _HubDailyPlanSummaryCard extends StatelessWidget {
  const _HubDailyPlanSummaryCard({required this.plan, required this.isDark});

  final DailyPlan plan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.dailyPlanProgressCount(
                plan.requiredCompletedCount,
                plan.totalItems,
              ),
              style: AppTypography.titleSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: plan.requiredProgress.clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubSectionHeader extends StatelessWidget {
  const _HubSectionHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(color: textSecondary),
        ),
      ],
    );
  }
}

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    this.route,
    this.onTap,
  }) : primary = false,
       assert(route != null || onTap != null, 'route or onTap required');

  const _HubActionCard.primary({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
    this.route,
    this.onTap,
  }) : primary = true,
       assert(route != null || onTap != null, 'route or onTap required');

  final IconData icon;
  final String title;
  final String description;
  final String? route;
  final VoidCallback? onTap;
  final bool isDark;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap ?? () => context.push(route!),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          gradient: primary
              ? LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.16),
                    accent.withValues(alpha: 0.06),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: accent.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: textPrimary,
                      fontFamily: 'Amiri',
                      fontWeight: primary ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              context.isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: accent,
              size: 15,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.03);
  }
}

class _UnifiedPathChoiceCard extends StatelessWidget {
  const _UnifiedPathChoiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(color: textColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: secondaryTextColor,
                ),
              )
            else
              Icon(
                context.isArabic ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                color: secondaryTextColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

enum _KidsCardVariant { mission, journey, rewards }

class _KidsHubActionCard extends StatelessWidget {
  const _KidsHubActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.variant,
  });

  final IconData icon;
  final String title;
  final String description;
  final String route;
  final _KidsCardVariant variant;

  @override
  Widget build(BuildContext context) {
    Gradient? background;
    Color? backgroundColor;
    Color border;
    Color textPrimary;
    Color textSecondary;
    Color iconColor;
    Color iconBg;
    List<BoxShadow>? shadows;

    switch (variant) {
      case _KidsCardVariant.mission:
        background = KidsTheme.currentHouseGradient;
        border = KidsTheme.mintGlow;
        textPrimary = Colors.white;
        textSecondary = Colors.white.withValues(alpha: 0.82);
        iconColor = KidsTheme.nightSkyDark;
        iconBg = KidsTheme.goldStar;
        shadows = KidsTheme.softGlow;
        break;
      case _KidsCardVariant.journey:
        backgroundColor = KidsTheme.creamParchment;
        border = KidsTheme.parchmentEdge;
        textPrimary = KidsTheme.nightSkyDark;
        textSecondary = KidsTheme.nightSkyMid.withValues(alpha: 0.72);
        iconColor = KidsTheme.forestGreen;
        iconBg = KidsTheme.forestGreen.withValues(alpha: 0.12);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ];
        break;
      case _KidsCardVariant.rewards:
        background = KidsTheme.completedHouseGradient;
        border = KidsTheme.goldStar;
        textPrimary = KidsTheme.nightSkyDark;
        textSecondary = KidsTheme.nightSkyMid.withValues(alpha: 0.72);
        iconColor = Colors.white;
        iconBg = KidsTheme.forestGreen;
        shadows = KidsTheme.goldGlow;
        break;
    }

    return InkWell(
      onTap: () => context.push(route),
      borderRadius: KidsTheme.cardRadius,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: background,
          borderRadius: KidsTheme.cardRadius,
          border: Border.all(color: border, width: 1.5),
          boxShadow: shadows,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: textPrimary,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              context.isArabic
                  ? Icons.arrow_back_ios_new_rounded
                  : Icons.arrow_forward_ios_rounded,
              color: textPrimary.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.03);
  }
}
