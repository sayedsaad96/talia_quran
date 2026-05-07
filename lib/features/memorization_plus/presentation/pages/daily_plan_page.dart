import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
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

class _DailyPlanView extends StatelessWidget {
  const _DailyPlanView({required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return BlocConsumer<DailyPlanCubit, DailyPlanState>(
      listener: (context, state) {
        if (state is DailyPlanLoaded && state.newAwards.isNotEmpty) {
          HapticFeedback.heavyImpact();
          unawaited(showCertificateCelebrationDialog(context, state.newAwards));
          return;
        }

        // UX-011: Show celebration when all items are completed
        if (state is DailyPlanLoaded &&
            state.plan.totalItems > 0 &&
            state.plan.completedCount >= state.plan.totalItems &&
            state.lastEvaluatedAyah != null) {
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
                  onPressed: () {
                    // Extract all ayahs for today
                    final ayahs = [
                      ...currentPlan!.newAyahs,
                      ...currentPlan.nearRevision,
                      ...currentPlan.farRevision,
                    ];
                    final numbers = ayahs
                        .map((a) => a.ayahNumber)
                        .toSet()
                        .toList();
                    if (numbers.isNotEmpty) {
                      context
                          .push(
                            '/memorization-plus/quiz',
                            extra: {'surahId': surahId, 'ayahNumbers': numbers},
                          )
                          .then((_) {
                            // Refresh plan after quiz
                            if (context.mounted) {
                              context.read<DailyPlanCubit>().refresh(
                                surahId: surahId,
                              );
                            }
                          });
                    }
                  },
                  backgroundColor: primary,
                  icon: const Icon(Icons.quiz_rounded, color: Colors.white),
                  label: Text(
                    'اختبر حفظك',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          body: () {
            if (state is DailyPlanLoading || state is DailyPlanInitial) {
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
                  if (plan.totalItems == 0)
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
                        label: '📖 آيات جديدة للحفظ',
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
                        label: '🔄 مراجعة قريبة (آخر ٥ أيام)',
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
                        label: '📅 مراجعة بعيدة',
                        ayahs: plan.farRevision,
                        plan: plan,
                        isDark: isDark,
                        primary: const Color(0xFFFF8C42),
                        evaluatingAyah: evaluatingAyah,
                        sectionColor: const Color(0xFFFF8C42),
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
              'ما شاء الله! أكملت خطتك اليومية',
              style: AppTypography.headlineSmall.copyWith(
                color: textPrimary,
                fontFamily: 'Amiri',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'أتممت ${plan.totalItems} عناصر بنجاح.\nثابر على هذا المستوى!',
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
                  label: 'آيات جديدة',
                  value: '${plan.newAyahs.length}',
                  color: primary,
                  isDark: isDark,
                ),
                _CelebrationStat(
                  icon: Icons.replay_rounded,
                  label: 'مراجعة',
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
                  'بارك الله فيك ✨',
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
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'تحديث الخطة',
          onPressed: () =>
              context.read<DailyPlanCubit>().refresh(surahId: surahId),
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
                    'خطتك اليومية',
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    '${plan.totalItems} عنصر • ${plan.completedCount} مكتمل',
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
            percent: plan.progress,
            center: Text(
              '${(plan.progress * 100).toInt()}%',
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
                  '${plan.completedCount} من ${plan.totalItems}',
                  style: AppTypography.titleLarge.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  plan.completedCount >= plan.totalItems
                      ? '✅ أحسنت! أكملت خطتك اليوم'
                      : 'تبقّى ${plan.totalItems - plan.completedCount} عناصر',
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
                  'آية ${planAyah.ayahNumber}',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    fontFamily: 'Amiri',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  planAyah.ayahText,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontFamily: 'Amiri',
                    height: 1.8,
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
              ],
            ),
            subtitle: planAyah.record != null
                ? Text(
                    'قوة: ${planAyah.record!.strengthLevel} • '
                    'مراجعات: ${planAyah.record!.totalReviews}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                    ),
                  )
                : Text(
                    'جديدة',
                    style: AppTypography.bodySmall.copyWith(color: primary),
                  ),
          ),
          // Evaluation buttons (show only if not yet done)
          if (!isDone && !isEvaluating)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  _EvalButton(
                    label: 'ضعيف',
                    icon: Icons.sentiment_dissatisfied_rounded,
                    color: Colors.red,
                    onTap: () => context.read<DailyPlanCubit>().evaluateAyah(
                      surahId: planAyah.surahId,
                      ayahNumber: planAyah.ayahNumber,
                      rating: PerformanceRating.weak,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EvalButton(
                    label: 'متوسط',
                    icon: Icons.sentiment_neutral_rounded,
                    color: const Color(0xFFFF8C42),
                    onTap: () => context.read<DailyPlanCubit>().evaluateAyah(
                      surahId: planAyah.surahId,
                      ayahNumber: planAyah.ayahNumber,
                      rating: PerformanceRating.average,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EvalButton(
                    label: 'ممتاز',
                    icon: Icons.sentiment_very_satisfied_rounded,
                    color: const Color(0xFF2D8E4C),
                    onTap: () => context.read<DailyPlanCubit>().evaluateAyah(
                      surahId: planAyah.surahId,
                      ayahNumber: planAyah.ayahNumber,
                      rating: PerformanceRating.excellent,
                    ),
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
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
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
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
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
        '✅ ممتاز! تم جدولة مراجعة الآية $ayahNumber بعد فترة أطول',
      ),
      PerformanceRating.average => (
        const Color(0xFFFF8C42),
        '⏰ متوسط، سيتم المراجعة خلال فترة معتدلة',
      ),
      PerformanceRating.weak => (
        Colors.red,
        '🔁 ضعيف، ستتم مراجعة الآية $ayahNumber غداً',
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
              'أحسنت! لا توجد مراجعات مطلوبة اليوم',
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
              'تفقّد غداً لمتابعة جدولك',
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
