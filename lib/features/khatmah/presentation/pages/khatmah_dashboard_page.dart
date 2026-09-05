import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_reading_result.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';
import '../cubits/khatmah_cubit.dart';
import '../khatmah_localizations.dart';
import '../widgets/khatmah_progress_gauge.dart';

class KhatmahDashboardPage extends StatefulWidget {
  const KhatmahDashboardPage({super.key, this.cubit});

  final KhatmahCubit? cubit;

  @override
  State<KhatmahDashboardPage> createState() => _KhatmahDashboardPageState();
}

class _KhatmahDashboardPageState extends State<KhatmahDashboardPage>
    with WidgetsBindingObserver {
  late final KhatmahCubit _cubit;
  bool _createdOwnCubit = false;
  bool _resumeNavigationInFlight = false;
  bool _mushafDialogOpen = false;
  bool _hasNavigatedToCompletion = false;
  bool _adjusting = false;

  List<Widget> _historyAction(BuildContext context) => [
    IconButton(
      key: const Key('khatmah_dashboard_history_button'),
      tooltip: context.l10n.khatmahRecentCompletions,
      onPressed: () => context.push(AppRoutes.khatmahHistory),
      icon: const Icon(Icons.history_rounded),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      try {
        _cubit = context.read<KhatmahCubit>();
      } catch (_) {
        _cubit = getIt<KhatmahCubit>();
        _createdOwnCubit = true;
      }
    }
    _cubit.load();
    _cubit.watchCalendar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.unwatchCalendar();
    if (_createdOwnCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _cubit.refreshDate();
  }

  void _showMushafLoggerDialog(BuildContext context, KhatmahPlan plan) {
    _mushafDialogOpen = true;
    showDialog<bool>(
      context: context,
      builder: (ctx) => _PhysicalMushafLoggerDialog(cubit: _cubit, plan: plan),
    ).then((saved) {
      _mushafDialogOpen = false;
      if (saved != true || !context.mounted) return;
      if (_cubit.state is KhatmahCompleted) {
        _openCompletion(_cubit.state as KhatmahCompleted);
        return;
      }
      context.showSnackBar(
        context.l10n.khatmahPhysicalMushafProgressSavedSuccessfully,
      );
    });
  }

  void _showAbandonConfirmDialog(
    BuildContext context,
    KhatmahPlan confirmedPlan,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.l10n.khatmahEndKhatmah,
          style: AppTypography.titleMedium,
        ),
        content: Text(
          context.l10n.khatmahAreYouSureYouWantToEndThis,
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.khatmahCancel),
          ),
          TextButton(
            key: const Key('khatmah_dashboard_abandon_confirm_button'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _cubit.abandonPlan(expectedPlan: confirmedPlan);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.khatmahEndKhatmah),
          ),
        ],
      ),
    );
  }

  Future<void> _resumeAndOpenReader() async {
    if (_resumeNavigationInFlight) return;
    _resumeNavigationInFlight = true;
    try {
      final resumed = await _cubit.resume();
      if (!mounted || resumed == null) return;
      await context.push('/quran/page/${resumed.nextUnreadPage}?mode=khatmah');
      if (mounted) await _cubit.load();
    } finally {
      _resumeNavigationInFlight = false;
    }
  }

  void _openCompletion(KhatmahCompleted state) {
    if (!mounted || _mushafDialogOpen || _hasNavigatedToCompletion) return;
    _hasNavigatedToCompletion = true;
    context.go(
      AppRoutes.khatmahCompletion,
      extra: KhatmahReadingResult(
        plan: state.plan,
        historyEntry: state.historyEntry,
        newlyCompletedPages: state.newlyCompletedPages,
      ),
    );
  }

  Future<void> _adjust(bool compensation) async {
    if (_adjusting) return;
    setState(() => _adjusting = true);
    final saved = compensation
        ? await _cubit.mildCompensation(1)
        : await _cubit.calmAdjustment();
    if (!mounted) return;
    setState(() => _adjusting = false);
    if (saved) {
      context.showSnackBar(
        compensation
            ? context.l10n.khatmahAdded1PageDayMildCompensation
            : context.l10n.khatmahEndDateRecalibratedSmoothly,
      );
    }
  }

  Widget _buildProgressFailureBanner(
    BuildContext context,
    KhatmahProgressFailure failure,
  ) {
    final errorColor = Theme.of(context).colorScheme.error;
    final canRetryProgress = failure.plan != null;
    return Container(
      key: const Key('khatmah_dashboard_progress_failure_banner'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: errorColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: errorColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.khatmahUnableToSaveKhatmahProgress,
              key: const Key('khatmah_dashboard_progress_failure_message'),
              style: AppTypography.bodySmall.copyWith(color: errorColor),
            ),
          ),
          TextButton(
            key: const Key('khatmah_dashboard_failure_retry_button'),
            onPressed: canRetryProgress
                ? _cubit.retryLastProgress
                : _cubit.load,
            child: Text(context.l10n.khatmahRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildDedicationBadge(
    KhatmahDedication dedication,
    bool isArabic,
    bool isDark,
  ) {
    final recipient = dedication.recipientName ?? '';
    final conditionLabel = localizedKhatmahCondition(
      context,
      dedication.condition,
    );
    final fullText = conditionLabel.isNotEmpty
        ? '$recipient ($conditionLabel)'
        : recipient;

    return Container(
      key: const Key('khatmah_dashboard_dedication_badge'),
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_rounded, size: 14, color: AppColors.gold),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              context.l10n.khatmahDedicatedTo((fullText).toString()),
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.goldLight : AppColors.goldDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isArabic = context.isArabic;
    final l10n = context.l10n;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return BlocProvider<KhatmahCubit>.value(
      value: _cubit,
      child: BlocConsumer<KhatmahCubit, KhatmahState>(
        listener: (_, state) {
          if (state is KhatmahCompleted) _openCompletion(state);
        },
        builder: (context, state) {
          if (state is KhatmahLoading || state is KhatmahInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is KhatmahProgressFailure && state.plan == null) {
            return Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.khatmahKhatmahDashboard),
                centerTitle: true,
                actions: _historyAction(context),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        key: const Key('khatmah_dashboard_load_failure'),
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.l10n.khatmahUnableToLoadYourKhatmah,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.khatmahCheckYourConnectionAndTryAgain,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        key: const Key(
                          'khatmah_dashboard_load_failure_retry_button',
                        ),
                        onPressed: _cubit.load,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.l10n.khatmahReload),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state is KhatmahNoActivePlan) {
            return Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.khatmahQuranKhatmah),
                centerTitle: true,
                actions: _historyAction(context),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 64,
                        color: primary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.khatmahNoPlanTitle,
                        style: AppTypography.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.khatmahNoPlanDescription,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton.icon(
                        key: const Key('khatmah_dashboard_start_button'),
                        onPressed: () => context.go(AppRoutes.khatmahSetup),
                        style: FilledButton.styleFrom(backgroundColor: primary),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.khatmahStartAction),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          KhatmahPlan plan;
          int wirdStartPage;
          int wirdEndPage;

          if (state is KhatmahActive) {
            plan = state.plan;
            wirdStartPage = state.wirdStartPage;
            wirdEndPage = state.wirdEndPage;
          } else if (state is KhatmahPaused) {
            plan = state.plan;
            final wird = plan.dailyTargetFor(_cubit.displayDate);
            wirdStartPage = wird.startPage;
            wirdEndPage = wird.endPage;
          } else if (state is KhatmahResuming) {
            plan = state.plan;
            final wird = plan.dailyTargetFor(_cubit.displayDate);
            wirdStartPage = wird.startPage;
            wirdEndPage = wird.endPage;
          } else if (state is KhatmahProgressFailure && state.plan != null) {
            plan = state.plan!;
            final wird = plan.dailyTargetFor(_cubit.displayDate);
            wirdStartPage = wird.startPage;
            wirdEndPage = wird.endPage;
          } else if (state is KhatmahWirdCompleted) {
            plan = state.plan;
            final wird = plan.dailyTargetFor(_cubit.displayDate);
            wirdStartPage = wird.startPage;
            wirdEndPage = wird.endPage;
          } else if (state is KhatmahCompleted) {
            plan = state.plan;
            wirdStartPage = 604;
            wirdEndPage = 604;
          } else {
            return const SizedBox.shrink();
          }

          final wirdPagesCount = wirdEndPage - wirdStartPage + 1;
          final isPaused = plan.status == KhatmahStatus.paused;
          final isResuming = state is KhatmahResuming;
          final dailyComplete = plan.isDailyTargetComplete(_cubit.displayDate);
          final wirdStartStr = isArabic
              ? MushafHizbHelper.toArabicNumber(wirdStartPage)
              : wirdStartPage.toString();
          final wirdEndStr = isArabic
              ? MushafHizbHelper.toArabicNumber(wirdEndPage)
              : wirdEndPage.toString();
          final wirdPagesCountStr = isArabic
              ? MushafHizbHelper.toArabicNumber(wirdPagesCount)
              : wirdPagesCount.toString();

          return Scaffold(
            appBar: AppBar(
              title: Text(
                context.l10n.khatmahKhatmahDashboard,
                style: AppTypography.titleMedium,
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                ..._historyAction(context),
                IconButton(
                  key: const Key('khatmah_dashboard_abandon_button'),
                  tooltip: context.l10n.khatmahEndKhatmah,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _showAbandonConfirmDialog(context, plan),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with Plan Title & Dedication Badge
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            localizedKhatmahPlanTitle(context, plan.title),
                            key: const Key('khatmah_dashboard_title'),
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (plan.dedication.isDedicated &&
                              plan.dedication.recipientName != null &&
                              plan.dedication.recipientName!.isNotEmpty)
                            _buildDedicationBadge(
                              plan.dedication,
                              isArabic,
                              isDark,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (state is KhatmahProgressFailure)
                      _buildProgressFailureBanner(context, state),
                    if (state is KhatmahProgressFailure)
                      const SizedBox(height: AppSpacing.md),

                    // Progress Gauge
                    KhatmahProgressGauge(plan: plan),
                    const SizedBox(height: AppSpacing.md),

                    // Today's Wird Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  AppColors.darkSurfaceVariant,
                                  AppColors.darkCard,
                                ]
                              : [
                                  primary.withValues(alpha: 0.08),
                                  AppColors.lightCard,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                color: primary,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  dailyComplete
                                      ? (context
                                            .l10n
                                            .khatmahTodaySWirdCompleted)
                                      : (context.l10n.khatmahTodaySWird),
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                context.l10n.khatmahPages(
                                  (wirdPagesCountStr).toString(),
                                ),
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.l10n.khatmahPagesTo(
                              (wirdStartStr).toString(),
                              (wirdEndStr).toString(),
                            ),
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            key: const Key(
                              'khatmah_dashboard_continue_reading_button',
                            ),
                            onPressed: isResuming
                                ? null
                                : isPaused
                                ? () => unawaited(_resumeAndOpenReader())
                                : () => context.push(
                                    '/quran/page/${plan.nextUnreadPage}?mode=khatmah',
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            icon: isResuming
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.menu_book_rounded,
                                  ),
                            label: Text(
                              isResuming
                                  ? (context.l10n.khatmahResuming)
                                  : isPaused
                                  ? l10n.khatmahResumeAction
                                  : (context.l10n.khatmahContinueReading),
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Physical Mushaf Logger Card
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.khatmahReadFromPhysicalMushaf,
                            style: AppTypography.labelLarge,
                          ),
                          Text(
                            context.l10n.khatmahPhysicalRangeHint,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton(
                            key: const Key(
                              'khatmah_dashboard_log_mushaf_button',
                            ),
                            onPressed: plan.status == KhatmahStatus.paused
                                ? null
                                : () => _showMushafLoggerDialog(context, plan),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide(color: primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            child: Text(context.l10n.khatmahLog),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Adaptive Controls Section
                    Text(
                      context.l10n.khatmahCalmAdaptiveControls,
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      children: [
                        // Calm adjustment: recalibrate end date
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key(
                              'khatmah_dashboard_calm_adjustment_button',
                            ),
                            onPressed:
                                plan.status != KhatmahStatus.active ||
                                    _adjusting
                                ? null
                                : () => _adjust(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                                horizontal: AppSpacing.xs,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.update_rounded, size: 18),
                            label: Text(
                              context.l10n.khatmahCalmAdjust,
                              style: AppTypography.labelMedium,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Mild compensation: add 1-2 pages/day
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key(
                              'khatmah_dashboard_mild_compensation_button',
                            ),
                            onPressed:
                                plan.status != KhatmahStatus.active ||
                                    _adjusting
                                ? null
                                : () => _adjust(true),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                                horizontal: AppSpacing.xs,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                            ),
                            label: Text(
                              context.l10n.khatmahMildBoost,
                              style: AppTypography.labelMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Pause / Resume button
                    OutlinedButton.icon(
                      key: const Key('khatmah_dashboard_pause_resume_button'),
                      onPressed: () {
                        if (plan.status == KhatmahStatus.active) {
                          _cubit.pause();
                        } else {
                          _cubit.resume();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                      ),
                      icon: Icon(
                        plan.status == KhatmahStatus.active
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(
                        plan.status == KhatmahStatus.active
                            ? (context.l10n.khatmahPause)
                            : (context.l10n.khatmahResume),
                        style: AppTypography.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhysicalMushafLoggerDialog extends StatefulWidget {
  const _PhysicalMushafLoggerDialog({required this.cubit, required this.plan});

  final KhatmahCubit cubit;
  final KhatmahPlan plan;

  @override
  State<_PhysicalMushafLoggerDialog> createState() =>
      _PhysicalMushafLoggerDialogState();
}

class _PhysicalMushafLoggerDialogState
    extends State<_PhysicalMushafLoggerDialog> {
  late final TextEditingController _controller;
  bool _isSaving = false;
  bool _saveFailed = false;
  bool _pausedError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final page = parseKhatmahPageInput(_controller.text);
    if (page == null ||
        page < widget.plan.nextUnreadPage ||
        page > KhatmahSchedulingEngine.totalPages ||
        _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    final saved = await widget.cubit.recordPhysicalRange(widget.plan, page);
    if (!mounted) return;
    final resultState = widget.cubit.state;
    if (!saved ||
        resultState is KhatmahProgressFailure ||
        resultState is KhatmahPaused) {
      setState(() {
        _isSaving = false;
        _saveFailed = true;
        _pausedError = resultState is KhatmahPaused;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;
    final page = parseKhatmahPageInput(_controller.text);
    final validRange =
        page != null && page >= widget.plan.nextUnreadPage && page <= 604;
    String number(int value) =>
        isArabic ? MushafHizbHelper.toArabicNumber(value) : value.toString();
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.khatmahLogPhysicalMushafReading,
              style: AppTypography.titleMedium,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.khatmahEnterTheLastPageReadFromYourPhysical,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('khatmah_dashboard_mushaf_page_input'),
              controller: _controller,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')),
              ],
              decoration: InputDecoration(
                labelText: context.l10n.khatmahPageNumber,
                hintText: context.l10n.khatmahEG(
                  widget.plan.nextUnreadPage.toString(),
                ),
                prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                validRange
                    ? context.l10n.khatmahConfirmRange(
                        number(widget.plan.nextUnreadPage),
                        number(page),
                      )
                    : context.l10n.khatmahRangeValidation(
                        number(widget.plan.nextUnreadPage),
                      ),
              ),
            ),
            if (_saveFailed) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _pausedError
                    ? context.l10n.khatmahIsPaused
                    : context.l10n.khatmahUnableToSaveKhatmahProgress,
                key: const Key('khatmah_dashboard_mushaf_save_error'),
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(context.l10n.khatmahCancel),
        ),
        FilledButton(
          key: const Key('khatmah_dashboard_mushaf_save_button'),
          onPressed: _isSaving || !validRange ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            _isSaving
                ? context.l10n.khatmahSaving
                : context.l10n.khatmahSaveProgress,
          ),
        ),
      ],
    );
  }
}
