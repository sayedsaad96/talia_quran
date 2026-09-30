import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/pending_ayah_resolver.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../../domain/services/plan_schedule_policy.dart';

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
      hasActivePlan: targets.hasActiveAdultPlan,
      blockSize: targets.memorizeBlockSize,
    );
  }

  void _retry() => setState(() => _loadFuture = _load());

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(title: Text(context.l10n.dailyPlanHeaderTitle)),
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
          if (!data.hasActivePlan) {
            return _EmptyPlanView(
              isDark: isDark,
              hasPlan: false,
              onCreatePlan: () async {
                await context.push(AppRoutes.memorizationPlusCustomPlan);
                if (mounted) _retry();
              },
            );
          }
          if (plan == null || plan.totalItems == 0) {
            return _EmptyPlanView(isDark: isDark, hasPlan: true);
          }

          return _DailyPlanBody(
            plan: plan,
            isDark: isDark,
            onOpenAyah: (ayah) async {
              await context.push(
                MemorizationNavigationResolver.dailyPlanAyahLocation(
                  ayah,
                  blockSize: data.blockSize == null
                      ? null
                      : PlanSchedulePolicy.fitToDailyPlan(
                          data.blockSize!,
                          plan,
                          surahId: ayah.surahId,
                          startAyah: ayah.ayahNumber,
                        ),
                ),
              );
              if (mounted) _retry();
            },
            onContinue: plan.isRequiredPlanCompleted
                ? null
                : () async {
                    await context.push(data.continueRoute);
                    if (mounted) _retry();
                  },
          );
        },
      ),
    );
  }
}

class _DailyPlanViewData {
  const _DailyPlanViewData({
    required this.plan,
    required this.continueRoute,
    required this.hasActivePlan,
    this.blockSize,
  });

  final DailyPlan? plan;
  final String continueRoute;
  final bool hasActivePlan;
  final int? blockSize;
}

class _DailyPlanBody extends StatelessWidget {
  const _DailyPlanBody({
    required this.plan,
    required this.isDark,
    required this.onOpenAyah,
    this.onContinue,
  });

  final DailyPlan plan;
  final bool isDark;
  final Future<void> Function(DailyPlanAyah ayah) onOpenAyah;
  final Future<void> Function()? onContinue;

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
          context.l10n.dailyPlanHeaderSummary(
            total,
            context.numText(total),
            context.numText(completed),
          ),
          style: AppTypography.titleMedium.copyWith(
            color: context.tokens.textPrimary,
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
              : context.l10n.dailyPlanRemainingItems(
                  total - completed,
                  context.numText(total - completed),
                ),
          style: AppTypography.bodyMedium.copyWith(
            color: context.tokens.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (plan.isReviewDay)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              key: const Key('daily_plan_review_day_notice'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.self_improvement_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.dailyPlanReviewDayNotice,
                      style: AppTypography.bodySmall.copyWith(
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (plan.newMemorizationBlocked && plan.newAyahs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      context.l10n.dailyPlanBacklogNotice(
                        plan.dueBacklogCount,
                        context.numText(plan.dueBacklogCount),
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (plan.newAyahs.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.dailyPlanNewAyahs,
            ayahs: plan.newAyahs,
            plan: plan,
            isDark: isDark,
            onOpenAyah: onOpenAyah,
          ),
        if (plan.weakRecovery.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.performanceWeak,
            ayahs: plan.weakRecovery,
            plan: plan,
            isDark: isDark,
            onOpenAyah: onOpenAyah,
          ),
        if (plan.nearRevision.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.dailyPlanNearRevision,
            ayahs: plan.nearRevision,
            plan: plan,
            isDark: isDark,
            onOpenAyah: onOpenAyah,
          ),
        if (plan.farRevision.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.dailyPlanFarRevision,
            ayahs: plan.farRevision,
            plan: plan,
            isDark: isDark,
            onOpenAyah: onOpenAyah,
          ),
        if (plan.retentionReview.isNotEmpty)
          _PlanBucketSection(
            title: context.l10n.dailyPlanRetentionReview,
            ayahs: plan.retentionReview,
            plan: plan,
            isDark: isDark,
            onOpenAyah: onOpenAyah,
          ),
        if (onContinue != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              PendingAyahResolver.firstPendingPlanTarget(plan)?.isNew == false
                  ? context.l10n.dailyPlanStartReview
                  : context.l10n.continueMemorizing,
            ),
          ),
        ],
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
    required this.onOpenAyah,
  });

  final String title;
  final List<DailyPlanAyah> ayahs;
  final DailyPlan plan;
  final bool isDark;
  final Future<void> Function(DailyPlanAyah ayah) onOpenAyah;

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
              color: context.tokens.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final ayah in ayahs)
            _PlanAyahTile(
              ayah: ayah,
              isCompleted: plan.isAyahCompleted(ayah.surahId, ayah.ayahNumber),
              isDark: isDark,
              onTap: () => onOpenAyah(ayah),
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
    required this.onTap,
  });

  final DailyPlanAyah ayah;
  final bool isCompleted;
  final bool isDark;
  final VoidCallback onTap;

  /// Strength bucket colour: weak → error, settling → warning, strong →
  /// success. Colour is never the only signal — labels accompany it.
  Color get _strengthColor => switch (ayah.strengthBand) {
    DailyPlanStrengthBand.unscheduled => AppColors.primary,
    DailyPlanStrengthBand.weak => AppColors.error,
    DailyPlanStrengthBand.learning => AppColors.warning,
    DailyPlanStrengthBand.strong => AppColors.success,
  };

  String _strengthLabel(BuildContext context) => switch (ayah.strengthBand) {
    DailyPlanStrengthBand.unscheduled => context.l10n.dailyPlanNewLabel,
    DailyPlanStrengthBand.weak => context.l10n.dailyPlanStrengthWeak,
    DailyPlanStrengthBand.learning => context.l10n.dailyPlanStrengthLearning,
    DailyPlanStrengthBand.strong => context.l10n.dailyPlanStrengthStrong,
  };

  @override
  Widget build(BuildContext context) {
    final record = ayah.record;
    final daysUntilReview = ayah.daysUntilReview(DateTime.now().toUtc());

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: context.tokens.card,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked,
          color: isCompleted ? AppColors.success : AppColors.primary,
        ),
        title: Text(
          // Plans mix surahs (new material + reviews), so the surah name is
          // required to identify the ayah.
          context.l10n.dailyPlanSurahAyahTitle(
            context.isArabic
                ? SurahNames.nameAr(ayah.surahId)
                : SurahNames.nameEn(ayah.surahId),
            context.numText(ayah.ayahNumber),
          ),
          style: AppTypography.bodyLarge,
        ),
        subtitle: record == null
            ? Text(
                context.l10n.dailyPlanNewLabel,
                style: AppTypography.bodySmall,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _strengthColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          // A plain label; raw strength/review counts are
                          // internal scheduling numbers, not learner-facing.
                          _strengthLabel(context),
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (daysUntilReview != null)
                    Text(
                      context.l10n.dailyPlanNextReviewInDays(
                        daysUntilReview.clamp(1, 999),
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: context.tokens.textHint,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyPlanView extends StatelessWidget {
  const _EmptyPlanView({
    required this.isDark,
    required this.hasPlan,
    this.onCreatePlan,
  });

  final bool isDark;

  /// False when no active plan exists: invite the learner to create one
  /// instead of congratulating them on an empty day.
  final bool hasPlan;
  final Future<void> Function()? onCreatePlan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasPlan
                  ? Icons.event_available_rounded
                  : Icons.edit_calendar_rounded,
              size: 64,
              color: context.tokens.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasPlan
                  ? context.l10n.dailyPlanEmptyTitle
                  : context.l10n.dailyPlanNoPlanTitle,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hasPlan
                  ? context.l10n.dailyPlanEmptySubtitle
                  : context.l10n.dailyPlanNoPlanSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
            if (!hasPlan && onCreatePlan != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                key: const Key('daily_plan_create_plan_button'),
                onPressed: onCreatePlan,
                icon: const Icon(Icons.add_rounded),
                label: Text(context.l10n.dailyPlanCreatePlanAction),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
