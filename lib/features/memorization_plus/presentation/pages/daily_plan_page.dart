import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/v2/v2_feature_flag.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/ayah_listen_button.dart';
import '../../../../core/widgets/qcf_hifz_verse_view.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../core/router/app_router.dart';
import '../../../certificate/presentation/widgets/certificate_celebration_dialog.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/daily_plan_cubit.dart';

class DailyPlanPage extends StatelessWidget {
  const DailyPlanPage({super.key, required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DailyPlanCubit>()..load(surahId: surahId),
      child: _DailyPlanView(surahId: surahId),
    );
  }
}

class _DailyPlanView extends StatefulWidget {
  const _DailyPlanView({required this.surahId});
  final int surahId;

  @override
  State<_DailyPlanView> createState() => _DailyPlanViewState();
}

class _DailyPlanViewState extends State<_DailyPlanView> {
  bool _completionCelebrationShown = false;

  @override
  Widget build(BuildContext context) {
    final surahId = widget.surahId;
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return BlocConsumer<DailyPlanCubit, DailyPlanState>(
      listenWhen: (previous, current) {
        if (current is DailyPlanLoaded && current.actionError != null) {
          return previous is! DailyPlanLoaded ||
              previous.actionError != current.actionError;
        }
        return true;
      },
      listener: (context, state) {
        if (state is DailyPlanLoaded && state.actionError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.actionError!)));
          return;
        }

        if (state is DailyPlanKidsRedirect) {
          context.go(AppRoutes.memorizationPlusKidsHome);
          return;
        }

        if (state is DailyPlanLoaded && state.newAwards.isNotEmpty) {
          HapticFeedback.heavyImpact();
          unawaited(showCertificateCelebrationDialog(context, state.newAwards));
          return;
        }

        // UX-011: Show celebration only when all *required* items are done.
        // P0 hotfix: retention-only completion must NOT trigger this.
        if (state is DailyPlanLoaded &&
            state.plan.isRequiredPlanCompleted &&
            state.lastEvaluatedAyah != null) {
          if (_completionCelebrationShown) return;
          _completionCelebrationShown = true;
          HapticFeedback.heavyImpact();
          _showCompletionCelebration(context, isDark, primary, state.plan);
        }
      },
      builder: (context, state) {
        DailyPlan? currentPlan;
        if (state is DailyPlanLoaded) currentPlan = state.plan;
        if (state is DailyPlanEvaluating) currentPlan = state.plan;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          floatingActionButton:
              currentPlan != null && currentPlan.totalItems > 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openPracticeFlow(context, currentPlan!),
                  backgroundColor: primary,
                  icon: const Icon(Icons.quiz_rounded, color: Colors.white),
                  label: Text(
                    context.l10n.dailyPlanQuizAction,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          body: () {
            if (state is DailyPlanLoading ||
                state is DailyPlanInitial ||
                state is DailyPlanKidsRedirect) {
              return const Center(child: LoadingWidget());
            }
            if (state is DailyPlanError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: () =>
                    context.read<DailyPlanCubit>().load(surahId: surahId),
              );
            }
            if (state is DailyPlanLoaded || state is DailyPlanEvaluating) {
              final plan = currentPlan!;
              final evaluatingAyah = state is DailyPlanEvaluating
                  ? state.evaluatingAyah
                  : null;
              final lastRating = state is DailyPlanLoaded
                  ? state.lastRating
                  : null;
              final lastEvaluated = state is DailyPlanLoaded
                  ? state.lastEvaluatedAyah
                  : null;

              return CustomScrollView(
                slivers: [
                  _buildAppBar(context, isDark, primary, plan),
                  if (plan.totalItems == 0 && !plan.hasRetentionReview)
                    SliverFillRemaining(child: _EmptyPlan(isDark: isDark))
                  else ...[
                    // Progress header
                    SliverToBoxAdapter(
                      child: _PlanProgressHeader(
                        plan: plan,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),

                    // Rating result snackbar
                    if (lastRating != null && lastEvaluated != null)
                      SliverToBoxAdapter(
                        child: _RatingBanner(
                          rating: lastRating,
                          ayahNumber: lastEvaluated,
                          isDark: isDark,
                        ),
                      ),

                    // New Ayahs
                    if (plan.newAyahs.isNotEmpty)
                      _AyahSection(
                        label: '📖 ${context.l10n.dailyPlanNewAyahs}',
                        ayahs: plan.newAyahs,
                        plan: plan,
                        isDark: isDark,
                        primary: primary,
                        evaluatingAyah: evaluatingAyah,
                        sectionColor: primary,
                      ),

                    // Near revision
                    if (plan.nearRevision.isNotEmpty)
                      _AyahSection(
                        label: '🔄 ${context.l10n.dailyPlanNearRevision}',
                        ayahs: plan.nearRevision,
                        plan: plan,
                        isDark: isDark,
                        primary: const Color(0xFF2D8E4C),
                        evaluatingAyah: evaluatingAyah,
                        sectionColor: const Color(0xFF2D8E4C),
                      ),

                    // Far revision
                    if (plan.farRevision.isNotEmpty)
                      _AyahSection(
                        label: '📅 ${context.l10n.dailyPlanFarRevision}',
                        ayahs: plan.farRevision,
                        plan: plan,
                        isDark: isDark,
                        primary: const Color(0xFFFF8C42),
                        evaluatingAyah: evaluatingAyah,
                        sectionColor: const Color(0xFFFF8C42),
                      ),

                    // Optional retention review (Sprint 10B)
                    if (plan.hasRetentionReview)
                      _RetentionReviewSection(
                        plan: plan,
                        isDark: isDark,
                        primary: primary,
                        evaluatingAyah: evaluatingAyah,
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ],
              );
            }
            return const SizedBox.shrink();
          }(),
        );
      },
    );
  }

  Future<void> _openPracticeFlow(BuildContext context, DailyPlan plan) async {
    final ayahs = [...plan.newAyahs, ...plan.nearRevision, ...plan.farRevision];
    final numbers = ayahs.map((a) => a.ayahNumber).toSet().toList();
    if (numbers.isEmpty) return;

    final v2Enabled = await V2FeatureFlag.isAdultEnabled();
    if (!context.mounted) return;

    final location = v2Enabled
        ? Uri(
            path: AppRoutes.memorizationV2Session,
            queryParameters: {
              'surahId': '${widget.surahId}',
              'startAyah':
                  '${plan.newAyahs.isNotEmpty ? plan.newAyahs.first.ayahNumber : numbers.first}',
              'blockSize':
                  '${plan.newAyahs.isNotEmpty ? plan.newAyahs.length : numbers.length}',
            },
          ).toString()
        : Uri(
            path: AppRoutes.memorizationPlusQuiz,
            queryParameters: {
              'surahId': '${widget.surahId}',
              'ayahNumbers': numbers.join(','),
            },
          ).toString();

    await context.push(location);
    if (!context.mounted) return;
    await context.read<DailyPlanCubit>().refresh(surahId: widget.surahId);
  }

  void _showCompletionCelebration(
    BuildContext context,
    bool isDark,
    Color primary,
    DailyPlan plan,
  ) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.dailyPlanCompletedTitle,
              style: AppTypography.headlineSmall.copyWith(
                color: textPrimary,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.dailyPlanCompletedSubtitle(plan.totalItems),
              style: AppTypography.bodyMedium.copyWith(
                color: textSecondary,
                fontFamily: 'Amiri',
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CelebrationStat(
                  icon: Icons.auto_stories_rounded,
                  label: context.l10n.dailyPlanNewAyahsShort,
                  value: '${plan.newAyahs.length}',
                  color: primary,
                  isDark: isDark,
                ),
                _CelebrationStat(
                  icon: Icons.replay_rounded,
                  label: context.l10n.dailyPlanReviewShort,
                  value:
                      '${plan.nearRevision.length + plan.farRevision.length}',
                  color: const Color(0xFF2D8E4C),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: Text(
                  context.l10n.dailyPlanBlessingAction,
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    bool isDark,
    Color primary,
    DailyPlan plan,
  ) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_suggest_rounded, color: Colors.white),
          tooltip: context.l10n.dailyPlanSettingsTooltip,
          onPressed: () => context.push(AppRoutes.memorizationPlusCustomPlan),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: context.l10n.dailyPlanRefreshTooltip,
          onPressed: () =>
              context.read<DailyPlanCubit>().refresh(surahId: widget.surahId),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.heroGradientDark
                : AppColors.heroGradientLight,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dailyPlanHeaderTitle,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    context.l10n.dailyPlanHeaderSummary(
                      plan.totalItems,
                      plan.requiredCompletedCount,
                    ),
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

// ─── Plan Progress Header ─────────────────────────────────────────────────────

class _PlanProgressHeader extends StatelessWidget {
  const _PlanProgressHeader({
    required this.plan,
    required this.isDark,
    required this.primary,
  });
  final DailyPlan plan;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 36,
            lineWidth: 5,
            percent: plan.requiredProgress,
            center: Text(
              '${(plan.requiredProgress * 100).toInt()}%',
              style: AppTypography.labelSmall.copyWith(
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            progressColor: primary,
            backgroundColor: primary.withValues(alpha: 0.1),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dailyPlanProgressCount(
                    plan.requiredCompletedCount,
                    plan.totalItems,
                  ),
                  style: AppTypography.titleLarge.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  plan.isRequiredPlanCompleted
                      ? context.l10n.dailyPlanAllDoneShort
                      : context.l10n.dailyPlanRemainingItems(
                          plan.totalItems - plan.requiredCompletedCount,
                        ),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontFamily: 'Amiri',
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

// ─── Retention Review Section (optional, collapsed by default) ───────────────

class _RetentionReviewSection extends StatefulWidget {
  const _RetentionReviewSection({
    required this.plan,
    required this.isDark,
    required this.primary,
    this.evaluatingAyah,
  });

  final DailyPlan plan;
  final bool isDark;
  final Color primary;
  final int? evaluatingAyah;

  @override
  State<_RetentionReviewSection> createState() =>
      _RetentionReviewSectionState();
}

class _RetentionReviewSectionState extends State<_RetentionReviewSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const sectionColor = Color(0xFF6B5B95);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.lg,
          AppSpacing.pagePadding,
          AppSpacing.sm,
        ),
        child: Material(
          color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: ExpansionTile(
            initiallyExpanded: _expanded,
            onExpansionChanged: (value) => setState(() => _expanded = value),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
            title: Text(
              '🔒 ${context.l10n.dailyPlanRetentionReview}',
              style: AppTypography.titleMedium.copyWith(
                color: sectionColor,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              context.l10n.dailyPlanRetentionReviewHint,
              style: AppTypography.bodySmall.copyWith(
                color: widget.isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontFamily: 'Amiri',
              ),
            ),
            children: [
              for (final ayah in widget.plan.retentionReview)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  child: _AyahPlanTile(
                    planAyah: ayah,
                    plan: widget.plan,
                    isDark: widget.isDark,
                    primary: widget.primary,
                    isEvaluating: widget.evaluatingAyah == ayah.ayahNumber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ayah Section ─────────────────────────────────────────────────────────────

class _AyahSection extends StatelessWidget {
  const _AyahSection({
    required this.label,
    required this.ayahs,
    required this.plan,
    required this.isDark,
    required this.primary,
    required this.sectionColor,
    this.evaluatingAyah,
  });

  final String label;
  final List<DailyPlanAyah> ayahs;
  final DailyPlan plan;
  final bool isDark;
  final Color primary;
  final Color sectionColor;
  final int? evaluatingAyah;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.lg,
            AppSpacing.pagePadding,
            AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              color: sectionColor,
              fontFamily: 'Amiri',
            ),
          ),
        ),
        ...ayahs.map(
          (a) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
              vertical: 4,
            ),
            child: _AyahPlanTile(
              planAyah: a,
              plan: plan,
              isDark: isDark,
              primary: primary,
              isEvaluating: evaluatingAyah == a.ayahNumber,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Ayah Plan Tile ───────────────────────────────────────────────────────────

class _AyahPlanTile extends StatelessWidget {
  const _AyahPlanTile({
    required this.planAyah,
    required this.plan,
    required this.isDark,
    required this.primary,
    required this.isEvaluating,
  });

  final DailyPlanAyah planAyah;
  final DailyPlan plan;
  final bool isDark;
  final Color primary;
  final bool isEvaluating;
  static const _ratingHintKey = 'daily_plan_rating_hint_seen';

  Future<void> _showRatingHintIfNeeded(BuildContext context) async {
    final prefs = getIt<SharedPreferences>();
    final seen = prefs.getBool(_ratingHintKey) ?? false;
    if (seen) return;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkDivider
                      : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Icon(Icons.psychology_alt_rounded, color: primary, size: 34),
              const SizedBox(height: AppSpacing.md),
              Text(
                sheetContext.l10n.dailyPlanRatingHintTitle,
                style: AppTypography.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                sheetContext.l10n.dailyPlanRatingHintBody,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontFamily: 'Amiri',
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(sheetContext.l10n.understood),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await prefs.setBool(_ratingHintKey, true);
  }

  Future<void> _evaluate(BuildContext context, PerformanceRating rating) async {
    await _showRatingHintIfNeeded(context);
    if (!context.mounted) return;
    await context.read<DailyPlanCubit>().evaluateAyah(
      surahId: planAyah.surahId,
      ayahNumber: planAyah.ayahNumber,
      rating: rating,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = plan.isCompleted(planAyah.ayahNumber);
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDone
            ? primary.withValues(alpha: 0.08)
            : isEvaluating
            ? primary.withValues(alpha: 0.05)
            : surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDone ? primary.withValues(alpha: 0.4) : border,
          width: isDone ? 1 : 0.5,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDone
                    ? primary.withValues(alpha: 0.15)
                    : primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: isDone
                    ? Icon(Icons.check_rounded, color: primary, size: 20)
                    : Text(
                        '${planAyah.ayahNumber}',
                        style: AppTypography.labelMedium.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.dailyPlanAyahTitle(planAyah.ayahNumber),
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    fontFamily: 'Amiri',
                  ),
                ),
                const SizedBox(height: 6),
                // T015: replaced with QcfHifzVerseView (compact mode)
                QcfHifzVerseView(
                  surahNumber: planAyah.surahId,
                  verseNumber: planAyah.ayahNumber,
                  fallbackText: planAyah.ayahText,
                  isUnlocked: true,
                  isMemorized: planAyah.record?.isMemorized ?? false,
                  displayMode: HifzVerseDisplayMode.compact,
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 4),
              ],
            ),
            subtitle: planAyah.record != null
                ? Text(
                    context.l10n.dailyPlanRecordStats(
                      planAyah.record!.strengthLevel,
                      planAyah.record!.totalReviews,
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                  )
                : Text(
                    context.l10n.dailyPlanNewLabel,
                    style: AppTypography.bodySmall.copyWith(color: primary),
                  ),
          ),
          // Listen button + Evaluation buttons (show only if not yet done)
          if (!isDone && !isEvaluating)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Listen row ──────────────────────────────────────────
                  Row(
                    children: [
                      AyahListenButton(
                        surahId: planAyah.surahId,
                        ayahNumber: planAyah.ayahNumber,
                        size: AyahListenButtonSize.small,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.dailyPlanListenBeforeRating,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextHint
                              : AppColors.lightTextHint,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // ── Rating buttons ──────────────────────────────────────
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useColumn = constraints.maxWidth < 340;
                      final buttons = [
                        _EvalButton(
                          label: context.l10n.performanceWeak,
                          description: context.l10n.dailyPlanRatingWeakDesc,
                          icon: Icons.sentiment_dissatisfied_rounded,
                          color: Colors.red,
                          expanded: !useColumn,
                          onTap: () =>
                              _evaluate(context, PerformanceRating.weak),
                        ),
                        _EvalButton(
                          label: context.l10n.performanceAverage,
                          description: context.l10n.dailyPlanRatingAverageDesc,
                          icon: Icons.sentiment_neutral_rounded,
                          color: const Color(0xFFFF8C42),
                          expanded: !useColumn,
                          onTap: () =>
                              _evaluate(context, PerformanceRating.average),
                        ),
                        _EvalButton(
                          label: context.l10n.performanceExcellent,
                          description:
                              context.l10n.dailyPlanRatingExcellentDesc,
                          icon: Icons.sentiment_very_satisfied_rounded,
                          color: const Color(0xFF2D8E4C),
                          expanded: !useColumn,
                          onTap: () =>
                              _evaluate(context, PerformanceRating.excellent),
                        ),
                      ];

                      if (useColumn) {
                        return Column(
                          children: [
                            for (var i = 0; i < buttons.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              buttons[i],
                            ],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          for (var i = 0; i < buttons.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            buttons[i],
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          if (isEvaluating)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _EvalButton extends StatelessWidget {
  const _EvalButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    this.expanded = true,
  });
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: expanded ? null : double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: color.withValues(alpha: 0.82),
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );

    return expanded ? Expanded(child: button) : button;
  }
}

// ─── Rating Banner ────────────────────────────────────────────────────────────

class _RatingBanner extends StatelessWidget {
  const _RatingBanner({
    required this.rating,
    required this.ayahNumber,
    required this.isDark,
  });
  final PerformanceRating rating;
  final int ayahNumber;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final (color, message) = switch (rating) {
      PerformanceRating.excellent => (
        const Color(0xFF2D8E4C),
        context.l10n.dailyPlanRatingExcellent(ayahNumber),
      ),
      PerformanceRating.average => (
        const Color(0xFFFF8C42),
        context.l10n.dailyPlanRatingAverage,
      ),
      PerformanceRating.weak => (
        Colors.red,
        context.l10n.dailyPlanRatingWeak(ayahNumber),
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Plan ───────────────────────────────────────────────────────────────

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.dailyPlanEmptyTitle,
              style: AppTypography.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.dailyPlanEmptySubtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Celebration Stat ─────────────────────────────────────────────────────────

class _CelebrationStat extends StatelessWidget {
  const _CelebrationStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
