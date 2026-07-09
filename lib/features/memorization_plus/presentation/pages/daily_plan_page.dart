import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

/// Read-only view of today's cached daily plan with bucket checkmarks (Sprint 3.2).
class DailyPlanPage extends StatefulWidget {
  const DailyPlanPage({super.key, this.repositoryOverride});

  /// Visible for widget tests — production uses [getIt].
  final MemorizationPlusRepository? repositoryOverride;

  @override
  State<DailyPlanPage> createState() => _DailyPlanPageState();
}

class _DailyPlanPageState extends State<DailyPlanPage> {
  late Future<_DailyPlanViewData> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<_DailyPlanViewData> _load() async {
    final repository =
        widget.repositoryOverride ?? getIt<MemorizationPlusRepository>();
    final planResult = await repository.getCachedDailyPlan();
    final plan = planResult.fold((_) => null, (value) => value);
    final targets = await MemorizationNavigationResolver(repository).resolve();
    return _DailyPlanViewData(
      plan: plan,
      continueRoute: targets.todayPlanLocation,
    );
  }

  void _retry() => setState(() => _loadFuture = _load());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.dailyPlanHeaderTitle),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<_DailyPlanViewData>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingWidget());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorStateWidget(
              message: context.l10n.errorOccurred,
              onRetry: _retry,
            );
          }

          final data = snapshot.data!;
          final plan = data.plan;
          if (plan == null || plan.totalItems == 0) {
            return _EmptyPlanView(isDark: isDark);
          }

          return _DailyPlanBody(
            plan: plan,
            continueRoute: data.continueRoute,
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _DailyPlanViewData {
  const _DailyPlanViewData({required this.plan, required this.continueRoute});

  final DailyPlan? plan;
  final String continueRoute;
}

class _DailyPlanBody extends StatelessWidget {
  const _DailyPlanBody({
    required this.plan,
    required this.continueRoute,
    required this.isDark,
  });

  final DailyPlan plan;
  final String continueRoute;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final completed = plan.requiredCompletedCount;
    final total = plan.totalItems;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          context.l10n.dailyPlanHeaderSummary(total, completed),
          style: AppTypography.titleMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: plan.requiredProgress.clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          plan.isRequiredPlanCompleted
              ? context.l10n.dailyPlanAllDoneShort
              : context.l10n.dailyPlanRemainingItems(total - completed),
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (plan.newAyahs.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.dailyPlanNewAyahs,
            ayahs: plan.newAyahs,
            plan: plan,
            isDark: isDark,
          ),
        if (plan.nearRevision.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.dailyPlanNearRevision,
            ayahs: plan.nearRevision,
            plan: plan,
            isDark: isDark,
          ),
        if (plan.farRevision.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.dailyPlanFarRevision,
            ayahs: plan.farRevision,
            plan: plan,
            isDark: isDark,
          ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => context.push(continueRoute),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(context.l10n.continueMemorizing),
        ),
      ],
    );
  }
}

class _PlanBucketSection extends StatelessWidget {
  const _PlanBucketSection({
    required this.title,
    required this.ayahs,
    required this.plan,
    required this.isDark,
  });

  final String title;
  final List<DailyPlanAyah> ayahs;
  final DailyPlan plan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final ayah in ayahs)
            _PlanAyahTile(
              ayah: ayah,
              isCompleted: plan.completedAyahNums.contains(ayah.ayahNumber),
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _PlanAyahTile extends StatelessWidget {
  const _PlanAyahTile({
    required this.ayah,
    required this.isCompleted,
    required this.isDark,
  });

  final DailyPlanAyah ayah;
  final bool isCompleted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: ListTile(
        leading: Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: isCompleted ? AppColors.success : AppColors.primary,
        ),
        title: Text(
          context.l10n.dailyPlanAyahTitle(ayah.ayahNumber),
          style: AppTypography.bodyLarge,
        ),
        subtitle: ayah.record == null
            ? Text(
                context.l10n.dailyPlanNewLabel,
                style: AppTypography.bodySmall,
              )
            : Text(
                context.l10n.dailyPlanRecordStats(
                  ayah.record!.strengthLevel,
                  ayah.record!.totalReviews,
                ),
                style: AppTypography.bodySmall,
              ),
      ),
    );
  }
}

class _EmptyPlanView extends StatelessWidget {
  const _EmptyPlanView({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.dailyPlanEmptyTitle,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.dailyPlanEmptySubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
