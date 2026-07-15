import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../theme/kids_theme.dart';

class MemorizationHubPage extends StatefulWidget {
  const MemorizationHubPage({super.key});

  @override
  State<MemorizationHubPage> createState() => _MemorizationHubPageState();
}

class _MemorizationHubPageState extends State<MemorizationHubPage> {
  late Future<_HubLoadResult> _hubFuture;

  @override
  void initState() {
    super.initState();
    _hubFuture = _loadHub();
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
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: FutureBuilder<_HubLoadResult>(
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
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _sectionsFor(
    BuildContext context,
    MemorizationNavigationTargets? targets,
    DailyPlan? dailyPlan,
    bool isDark,
  ) {
    final profile = targets?.profile;
    if (profile?.isAdult == true) {
      final adultTargets = targets!;
      return [
        _HubSectionHeader(
          title: context.l10n.dailyPlanHeaderTitle,
          subtitle: context.isArabic
              ? 'وجهتك الأساسية للحفظ والمراجعة اليومية.'
              : 'Your default place for daily memorization and review.',
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dailyPlan != null && dailyPlan.totalItems > 0)
          _HubDailyPlanSummaryCard(plan: dailyPlan, isDark: isDark),
        if (dailyPlan != null && dailyPlan.totalItems > 0)
          const SizedBox(height: AppSpacing.sm),
        _HubActionCard.primary(
          icon: Icons.today_rounded,
          title: context.isArabic ? 'أكمل خطة اليوم' : "Continue Today's Plan",
          description: context.isArabic
              ? 'افتح ورد الحفظ والمراجعة الحالي.'
              : 'Open your current memorization and review plan.',
          route: adultTargets.todayPlanLocation,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.checklist_rounded,
          title: context.isArabic ? 'تفاصيل خطة اليوم' : "View Today's Plan",
          description: context.l10n.dailyPlanProgressCount(
            dailyPlan?.requiredCompletedCount ?? 0,
            dailyPlan?.totalItems ?? 0,
          ),
          route: AppRoutes.memorizationPlusDailyPlan,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.isArabic ? 'التدريب' : 'Practice',
          subtitle: context.isArabic
              ? 'اختر سورة أو تدرب بالتسميع الصوتي.'
              : 'Choose a surah or use recite practice.',
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.auto_stories_rounded,
          title: context.isArabic ? 'تدرّب بالسورة' : 'Practice by Surah',
          description: context.isArabic
              ? 'تسميع صوتي واضح: اختر سورة وابدأ جلسة الحفظ.'
              : 'Recite Practice: choose a surah and start a speech-to-text session.',
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
          route: adultTargets.reviewQuizLocation,
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.isArabic ? 'الإعدادات' : 'Settings',
          subtitle: context.isArabic
              ? 'اضبط خطة الحفظ بدون تغيير المسار.'
              : 'Adjust the plan without changing memorization systems.',
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _HubActionCard(
          icon: Icons.settings_suggest_rounded,
          title: context.isArabic ? 'إعدادات الخطة' : 'Plan Settings',
          description: context.isArabic
              ? 'عدّل الخطة اليومية أو إعدادات مسار الحفظ.'
              : 'Adjust your daily plan or memorization path settings.',
          route: AppRoutes.memorizationPlusCustomPlan,
          isDark: isDark,
        ),
      ];
    }

    if (profile?.isChild == true) {
      return [
        _HubSectionHeader(
          title: context.isArabic ? 'المهمة الحالية' : 'Current Mission',
          subtitle: context.isArabic
              ? 'ابدأ من المهمة النشطة للطفل.'
              : 'Start from the child’s active mission.',
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KidsHubActionCard(
          icon: Icons.flag_rounded,
          title: context.isArabic ? 'المهمة الحالية' : 'Current Mission',
          description: context.isArabic
              ? 'ابدأ مهمة الحفظ التالية في رحلة الأطفال.'
              : 'Start the next memorization mission in the kids journey.',
          route: AppRoutes.memorizationPlusKidsHome,
          variant: _KidsCardVariant.mission,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.isArabic ? 'الرحلة' : 'Journey',
          subtitle: context.isArabic
              ? 'شاهد مراحل الطفل الحالية والقادمة.'
              : 'See current and upcoming journey stages.',
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KidsHubActionCard(
          icon: Icons.map_rounded,
          title: context.isArabic ? 'الرحلة' : 'Journey',
          description: context.isArabic
              ? 'شاهد المراحل الحالية والقادمة.'
              : 'See current and upcoming journey stages.',
          route: targets!.kidsJourneyLocation,
          variant: _KidsCardVariant.journey,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HubSectionHeader(
          title: context.isArabic ? 'المكافآت / التقدم' : 'Rewards / Progress',
          subtitle: context.isArabic
              ? 'راجع نجوم الطفل ونقاطه من شاشة التقدم.'
              : 'Review stars and points from Progress.',
          isDark: isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _KidsHubActionCard(
          icon: Icons.stars_rounded,
          title: context.isArabic ? 'المكافآت / التقدم' : 'Rewards / Progress',
          description: context.isArabic
              ? 'راجع النقاط والنجوم من شاشة التقدم.'
              : 'Review points and stars from the Progress screen.',
          route: AppRoutes.progress,
          variant: _KidsCardVariant.rewards,
        ),
      ];
    }

    return [
      _PathChoiceCard(
        icon: Icons.psychology_alt_rounded,
        title: context.isArabic ? 'حفظ الكبار' : 'Adult Memorization',
        description: context.isArabic
            ? 'خطة يومية وتدريب بالسورة واختبار مراجعة.'
            : "Today's plan, practice by surah, and review quiz.",
        isDark: isDark,
      ),
      const SizedBox(height: AppSpacing.md),
      _PathChoiceCard(
        icon: Icons.child_care_rounded,
        title: context.isArabic ? 'حفظ الأطفال' : 'Kids Memorization',
        description: context.isArabic
            ? 'مهام قصيرة ورحلة ومكافآت للطفل.'
            : 'Current mission, journey, and rewards for kids.',
        isDark: isDark,
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
                    colors: [Color(0xFF1A6B5A), Color(0xFF2D5A8E)],
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
                  const SizedBox(height: 4),
                  Text(
                    context.isArabic
                        ? 'مكان واحد لكل مسارات الحفظ'
                        : 'One place for every memorization path',
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
    required this.route,
    required this.isDark,
  }) : primary = false;

  const _HubActionCard.primary({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.isDark,
  }) : primary = true;

  final IconData icon;
  final String title;
  final String description;
  final String route;
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
      onTap: () => context.push(route),
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
                  const SizedBox(height: 4),
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

class _PathChoiceCard extends StatelessWidget {
  const _PathChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _HubActionCard(
      icon: icon,
      title: title,
      description: description,
      route: AppRoutes.memorizationPlus,
      isDark: isDark,
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
                  const SizedBox(height: 4),
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
