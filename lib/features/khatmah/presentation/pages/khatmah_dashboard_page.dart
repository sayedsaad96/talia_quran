import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../../../core/utils/locale_numeric_input_formatter.dart';
import '../../../../core/widgets/fallback_pop_scope.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_reading_result.dart';
import '../cubits/khatmah_cubit.dart';
import '../khatmah_localizations.dart';
import '../widgets/khatmah_dedication_form.dart';
import '../widgets/khatmah_juz_map.dart';
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
      icon: const Icon(TaliaIcons.history),
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

  Future<void> _showEditDedicationSheet(KhatmahPlan plan) async {
    var draft = plan.dedication;
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KhatmahDedicationForm(
                initialDedication: plan.dedication,
                onChanged: (value) => draft = value,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('khatmah_edit_dedication_save_button'),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(sheetContext.l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
    if (save != true || !mounted) return;
    final saved = await _cubit.updateDedication(draft);
    if (saved && mounted) {
      context.showSnackBar(context.l10n.khatmahDedicationSaved);
    }
  }

  Future<void> _resumeAndOpenReader() async {
    if (_resumeNavigationInFlight) return;
    _resumeNavigationInFlight = true;
    try {
      final resumed = await _cubit.resume();
      if (!mounted || resumed == null) return;
      await context.push('/quran/page/${resumed.nextUnreadPage}?mode=khatmah');
      if (mounted) await _cubit.load(showLoading: false);
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

  String _formatDate(DateTime date) {
    String part(int value, [int width = 2]) {
      final padded = value.toString().padLeft(width, '0');
      return context.digitText(padded);
    }

    return '${part(date.year, 4)}/${part(date.month)}/${part(date.day)}';
  }

  /// Shows the new pace and end date first; applies only on confirmation,
  /// then offers an undo.
  Future<void> _adjust(KhatmahAdjustment kind) async {
    if (_adjusting) return;
    final previous = _recordingPlanFrom(_cubit.state);
    final preview = _cubit.previewAdjustment(kind: kind);
    if (previous == null || preview == null) return;
    final pages = context.numText(preview.targetPagesPerDay);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.khatmahAdjustPreviewTitle),
        content: Text(
          dialogContext.l10n.khatmahAdjustPreviewBody(
            preview.targetPagesPerDay,
            pages,
            _formatDate(preview.expectedEndDate),
          ),
          key: const Key('khatmah_adjust_preview'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.khatmahCancel),
          ),
          FilledButton(
            key: const Key('khatmah_adjust_apply_button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.khatmahApplyAdjustment),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _adjusting = true);
    final saved = await _cubit.applyAdjustment(kind);
    if (!mounted) return;
    setState(() => _adjusting = false);
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (kind) {
            KhatmahAdjustment.mildBoost =>
              context.l10n.khatmahAdded1PageDayMildCompensation,
            KhatmahAdjustment.calm =>
              context.l10n.khatmahEndDateRecalibratedSmoothly,
            KhatmahAdjustment.keepEndDate => context.l10n.khatmahRedistributed,
          }),
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () => _cubit.undoScheduleAdjustment(previous),
          ),
        ),
      );
    }
  }

  /// Every catch-up choice the plan allows, each with its new pace and
  /// finish date, so the learner picks with the outcome in view.
  Future<void> _showCatchUpSheet() async {
    final choice = await showModalBottomSheet<KhatmahAdjustment>(
      context: context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        String number(int value) => sheetContext.numText(value);
        final options = [
          for (final kind in KhatmahAdjustment.values)
            if (_cubit.previewAdjustment(kind: kind) case final preview?)
              (kind: kind, preview: preview),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.khatmahCatchUpTitle,
                  style: AppTypography.titleMedium,
                ),
              ),
              for (final option in options)
                ListTile(
                  key: Key('khatmah_catchup_${option.kind.name}'),
                  title: Text(switch (option.kind) {
                    KhatmahAdjustment.calm => l10n.khatmahCalmAdjust,
                    KhatmahAdjustment.mildBoost => l10n.khatmahMildBoost,
                    KhatmahAdjustment.keepEndDate =>
                      l10n.khatmahRedistributeAction,
                  }),
                  subtitle: Text(
                    l10n.khatmahCatchUpOption(
                      number(option.preview.targetPagesPerDay),
                      _formatDate(option.preview.expectedEndDate),
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, option.kind),
                ),
            ],
          ),
        );
      },
    );
    if (choice != null && mounted) await _adjust(choice);
  }

  static KhatmahPlan? _recordingPlanFrom(KhatmahState state) => switch (state) {
    final KhatmahActive active => active.plan,
    final KhatmahWirdCompleted completed => completed.plan,
    final KhatmahProgressFailure failure => failure.plan,
    _ => null,
  };

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
          Icon(TaliaIcons.error, color: errorColor),
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

  Widget _buildDedicationBadge(KhatmahDedication dedication, bool isDark) {
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
          const Icon(TaliaIcons.heartFilled, size: 14, color: AppColors.gold),
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
    final l10n = context.l10n;
    final primary = context.tokens.accent;
    final cardBg = context.tokens.card;

    // Setup and completion reach the dashboard with `context.go`, leaving it
    // as the only route: back must lead home instead of closing the app.
    final hasHistory = FallbackPopScope.hasHistory(context);
    return FallbackPopScope(
      fallbackLocation: AppRoutes.home,
      child: BlocProvider<KhatmahCubit>.value(
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
                  leading: _fallbackBackButton(hasHistory),
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
                          TaliaIcons.error,
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
                          // Offline-first: a load failure is local (storage or
                          // account switch), never a connectivity problem.
                          context.l10n.khatmahLoadFailureHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          key: const Key(
                            'khatmah_dashboard_load_failure_retry_button',
                          ),
                          onPressed: _cubit.load,
                          icon: const Icon(TaliaIcons.refresh),
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
                  leading: _fallbackBackButton(hasHistory),
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
                          TaliaIcons.mushaf,
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
                            color: context.tokens.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton.icon(
                          key: const Key('khatmah_dashboard_start_button'),
                          onPressed: () => context.go(AppRoutes.khatmahSetup),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                          ),
                          icon: const Icon(TaliaIcons.add),
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
            final dailyComplete = plan.isDailyTargetComplete(
              _cubit.displayDate,
            );
            final wirdStartStr = context.numText(wirdStartPage);
            final wirdEndStr = context.numText(wirdEndPage);
            final wirdJuz = MushafHizbHelper.getJuz(wirdStartPage);
            final pagesRange = context.l10n.khatmahPagesTo(
              wirdStartStr,
              wirdEndStr,
            );
            final wirdJuzStr = context.numText(wirdJuz);
            final wirdRangeText = plan.wirdUnit == KhatmahWirdUnit.juz
                ? '${context.l10n.khatmahWirdJuz(wirdJuzStr)}${context.listSeparator}$pagesRange'
                : pagesRange;
            final wirdPagesCountStr = context.numText(wirdPagesCount);

            return Scaffold(
              appBar: AppBar(
                leading: _fallbackBackButton(hasHistory),
                title: Text(
                  context.l10n.khatmahKhatmahDashboard,
                  style: AppTypography.titleMedium,
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  ..._historyAction(context),
                  // A destructive action belongs in the overflow menu, not
                  // beside everyday navigation like history.
                  PopupMenuButton<void>(
                    key: const Key('khatmah_dashboard_more_menu'),
                    itemBuilder: (menuContext) => [
                      PopupMenuItem<void>(
                        key: const Key(
                          'khatmah_dashboard_edit_dedication_button',
                        ),
                        onTap: () => unawaited(_showEditDedicationSheet(plan)),
                        child: Row(
                          children: [
                            const Icon(TaliaIcons.dua),
                            const SizedBox(width: AppSpacing.sm),
                            Text(context.l10n.khatmahEditDedication),
                          ],
                        ),
                      ),
                      PopupMenuItem<void>(
                        key: const Key('khatmah_dashboard_abandon_button'),
                        onTap: () => _showAbandonConfirmDialog(context, plan),
                        child: Row(
                          children: [
                            Icon(
                              TaliaIcons.delete,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              context.l10n.khatmahEndKhatmah,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                              _buildDedicationBadge(plan.dedication, isDark),
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
                      if (plan.status == KhatmahStatus.active)
                        _PaceLine(
                          behind: plan.pagesBehind(_cubit.displayDate),
                          ahead: plan.daysAhead(_cubit.displayDate),
                          onRedistribute: _adjusting
                              ? null
                              : () => unawaited(_showCatchUpSheet()),
                        ),
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
                                  TaliaIcons.reading,
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
                                    wirdPagesCount,
                                    wirdPagesCountStr,
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
                              wirdRangeText,
                              style: AppTypography.bodyMedium.copyWith(
                                color: context.tokens.textSecondary,
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
                                          ? TaliaIcons.play
                                          : TaliaIcons.mushaf,
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
                                  : () =>
                                        _showMushafLoggerDialog(context, plan),
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

                      // Juz map: what is covered, and a way into any juz.
                      KhatmahJuzMap(
                        plan: plan,
                        enabled: plan.status == KhatmahStatus.active,
                        onOpenPage: (page) =>
                            context.push('/quran/page/$page?mode=khatmah'),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Adaptive Controls Section
                      Text(
                        context.l10n.khatmahCalmAdaptiveControls,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.tokens.textSecondary,
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
                                  : () => _adjust(KhatmahAdjustment.calm),
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
                              icon: const Icon(TaliaIcons.update, size: 18),
                              label: Text(
                                context.l10n.khatmahCalmAdjust,
                                style: AppTypography.labelMedium,
                              ),
                            ),
                          ),
                          // Mild compensation: add 1 page/day (pages mode only).
                          if (plan.wirdUnit == KhatmahWirdUnit.pages) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                key: const Key(
                                  'khatmah_dashboard_mild_compensation_button',
                                ),
                                onPressed:
                                    plan.status != KhatmahStatus.active ||
                                        _adjusting ||
                                        !_cubit.canBoost
                                    ? null
                                    : () =>
                                          _adjust(KhatmahAdjustment.mildBoost),
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
                                  TaliaIcons.addCircle,
                                  size: 18,
                                ),
                                label: Text(
                                  context.l10n.khatmahMildBoost,
                                  style: AppTypography.labelMedium,
                                ),
                              ),
                            ),
                          ],
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
                              ? TaliaIcons.pause
                              : TaliaIcons.play,
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
      ),
    );
  }

  /// Back affordance for a dashboard opened without history (null keeps the
  /// AppBar's default back button when there is a route to pop to).
  Widget? _fallbackBackButton(bool hasHistory) {
    if (hasHistory) return null;
    return IconButton(
      key: const Key('khatmah_dashboard_back_button'),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const BackButtonIcon(),
      onPressed: () => context.go(AppRoutes.home),
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
    if (page == null || widget.plan.pagesThrough(page).isEmpty || _isSaving) {
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
    final page = parseKhatmahPageInput(_controller.text);
    final validRange =
        page != null && widget.plan.pagesThrough(page).isNotEmpty;
    String number(int value) => context.numText(value);
    final wirdEnd = widget.plan
        .dailyTargetFor(widget.cubit.displayDate)
        .endPage;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(TaliaIcons.mushaf, color: AppColors.gold),
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
                LocaleNumericInputFormatter(
                  Localizations.localeOf(context).languageCode,
                ),
              ],
              decoration: InputDecoration(
                labelText: context.l10n.khatmahPageNumber,
                hintText: context.l10n.khatmahEG(
                  number(widget.plan.nextUnreadPage),
                ),
                prefixIcon: const Icon(TaliaIcons.bookmark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
            if (widget.plan.pagesThrough(wirdEnd).isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ActionChip(
                key: const Key('khatmah_mushaf_wird_end_chip'),
                avatar: const Icon(TaliaIcons.flag, size: 18),
                label: Text(
                  context.l10n.khatmahThroughWirdEnd(number(wirdEnd)),
                ),
                onPressed: _isSaving
                    ? null
                    : () => setState(
                        () => _controller.text = context.numText(wirdEnd),
                      ),
              ),
            ],
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

/// One calm line telling the learner whether the finish date still holds.
class _PaceLine extends StatelessWidget {
  const _PaceLine({required this.behind, this.ahead = 0, this.onRedistribute});

  final int behind;

  /// Whole days the projected finish beats the plan; shown when on track.
  final int ahead;

  /// Offered when behind: spread the remaining pages to keep the end date.
  final VoidCallback? onRedistribute;

  @override
  Widget build(BuildContext context) {
    final onTrack = behind == 0;
    final isAhead = onTrack && ahead > 0;
    final color = onTrack ? AppColors.success : AppColors.warning;
    String number(int value) => context.numText(value);
    final pages = number(behind);
    final line = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        key: const Key('khatmah_dashboard_pace'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAhead
                ? TaliaIcons.progress
                : onTrack
                ? TaliaIcons.checkCircle
                : TaliaIcons.clock,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              isAhead
                  ? context.l10n.khatmahPaceAhead(ahead, number(ahead))
                  : onTrack
                  ? context.l10n.khatmahPaceOnTrack
                  : context.l10n.khatmahPaceBehind(behind, pages),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
    if (onTrack) return line;
    return Column(
      children: [
        line,
        TextButton.icon(
          key: const Key('khatmah_dashboard_redistribute_button'),
          onPressed: onRedistribute,
          icon: const Icon(TaliaIcons.balance, size: 18),
          label: Text(context.l10n.khatmahRedistributeAction),
        ),
      ],
    );
  }
}
