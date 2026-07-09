import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/parent_dashboard_cubit.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key, required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ParentDashboardCubit>()..load(surahId: surahId),
      child: _ParentDashboardView(surahId: surahId),
    );
  }
}

class _ParentDashboardView extends StatefulWidget {
  const _ParentDashboardView({required this.surahId});
  final int surahId;

  @override
  State<_ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<_ParentDashboardView> {
  final _pinController = TextEditingController();
  final _rewardController = TextEditingController();
  int _lastShownFeedbackEventId = 0;

  @override
  void dispose() {
    _pinController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          context.l10n.parentDashboardTitle,
          style: AppTypography.titleLarge,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: BlocConsumer<ParentDashboardCubit, ParentDashboardState>(
        listener: (context, state) {
          final feedbackEventId = switch (state) {
            ParentDashboardNeedsPin(:final feedbackEventId) => feedbackEventId,
            ParentDashboardLocked(:final feedbackEventId) => feedbackEventId,
            ParentDashboardLoaded(:final feedbackEventId) => feedbackEventId,
            _ => 0,
          };
          final feedback = switch (state) {
            ParentDashboardNeedsPin(:final feedback) => feedback,
            ParentDashboardLocked(:final feedback) => feedback,
            ParentDashboardLoaded(:final feedback) => feedback,
            _ => null,
          };
          if (feedback != null && feedbackEventId > _lastShownFeedbackEventId) {
            _lastShownFeedbackEventId = feedbackEventId;
            context.showSnackBar(
              _feedbackMessage(context, feedback),
              isError: feedback.isError,
            );
          }
        },
        builder: (context, state) {
          if (state is ParentDashboardLoading ||
              state is ParentDashboardInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is ParentDashboardLinking ||
              state is ParentDashboardUnlinking) {
            return _ParentDashboardBusy(
              message: state is ParentDashboardLinking
                  ? context.l10n.parentDashboardLinking
                  : context.l10n.parentDashboardUnlinking,
            );
          }
          if (state is ParentDashboardError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<ParentDashboardCubit>().load(
                surahId: widget.surahId,
              ),
            );
          }
          if (state is ParentDashboardNeedsPin) {
            return _PinGate(
              title: context.l10n.parentDashboardCreatePinTitle,
              buttonText: context.l10n.parentDashboardSavePinButton,
              controller: _pinController,
              requiresConfirmation: true,
              onSubmit: (pin) => context.read<ParentDashboardCubit>().setPin(
                pin,
                surahId: widget.surahId,
              ),
            );
          }
          if (state is ParentDashboardLocked) {
            return _PinGate(
              title: context.l10n.parentDashboardEnterPinTitle,
              buttonText: context.l10n.parentDashboardEnterButton,
              controller: _pinController,
              onSubmit: (pin) => context.read<ParentDashboardCubit>().unlock(
                pin,
                surahId: widget.surahId,
              ),
              onReset: () => context.read<ParentDashboardCubit>().resetAccess(
                surahId: widget.surahId,
              ),
            );
          }
          if (state is ParentDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<ParentDashboardCubit>().refresh(
                surahId: widget.surahId,
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  120,
                ),
                children: [
                  _TodaySummaryCard(
                    dashboard: state.dashboard,
                    onAddReward: () => _showQuickRewardDialog(context),
                    onShowLastLog: () =>
                        _showLastSessionDialog(context, state.dashboard.logs),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SummaryCard(dashboard: state.dashboard),
                  const SizedBox(height: AppSpacing.lg),
                  _ReminderCard(settings: state.dashboard.settings),
                  const SizedBox(height: AppSpacing.lg),
                  _RemoteToolsCard(
                    children: state.remoteChildren,
                    onScan: () => _openScanner(context),
                    onManual: () => _showManualTokenDialog(context),
                    onAddReward: (childId) =>
                        _showRemoteRewardDialog(context, childId),
                    onRemoveChild: (childId, displayName) =>
                        _confirmRemoveChild(context, childId, displayName),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _RewardsCard(
                    rewards: state.dashboard.rewards,
                    controller: _rewardController,
                    onAdd: () {
                      context.read<ParentDashboardCubit>().addReward(
                        _rewardController.text,
                      );
                      _rewardController.clear();
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _LogsCard(logs: state.dashboard.logs),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _feedbackMessage(
    BuildContext context,
    ParentDashboardFeedback feedback,
  ) {
    final l10n = context.l10n;
    return switch (feedback.type) {
      ParentDashboardFeedbackType.pinInvalid => l10n.parentDashboardPinInvalid,
      ParentDashboardFeedbackType.pinIncorrect =>
        l10n.parentDashboardPinIncorrect,
      ParentDashboardFeedbackType.rewardAdded =>
        l10n.parentDashboardRewardAdded,
      ParentDashboardFeedbackType.remoteRewardAdded =>
        l10n.parentDashboardRemoteRewardAdded,
      ParentDashboardFeedbackType.childLinked =>
        l10n.parentDashboardChildLinked,
      ParentDashboardFeedbackType.childRemoved =>
        l10n.parentDashboardChildRemoved,
      ParentDashboardFeedbackType.reminderSaved =>
        l10n.parentDashboardReminderSaved,
      ParentDashboardFeedbackType.failure => feedback.message ?? '',
    };
  }

  Future<void> _openScanner(BuildContext context) async {
    final token = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _QrScannerPage()));
    if (token != null && context.mounted) {
      await context.read<ParentDashboardCubit>().acceptRemoteToken(
        token,
        surahId: widget.surahId,
      );
    }
  }

  Future<void> _showManualTokenDialog(BuildContext context) async {
    final controller = TextEditingController();
    final token = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.parentDashboardEnterLinkingCode),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.parentDashboardLinkHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.parentDashboardLinkAction),
          ),
        ],
      ),
    );
    controller.dispose();
    if (token != null && token.isNotEmpty && context.mounted) {
      await context.read<ParentDashboardCubit>().acceptRemoteToken(
        token,
        surahId: widget.surahId,
      );
    }
  }

  Future<void> _showRemoteRewardDialog(
    BuildContext context,
    String childId,
  ) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.parentDashboardRemoteRewardTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.parentDashboardRewardHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty && context.mounted) {
      await context.read<ParentDashboardCubit>().addRemoteReward(
        childId,
        title,
      );
    }
  }

  Future<void> _confirmRemoveChild(
    BuildContext context,
    String childId,
    String displayName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.parentDashboardRemoveChildConfirmTitle),
        content: Text(
          dialogContext.l10n.parentDashboardRemoveChildConfirmBody(
            displayName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.parentDashboardRemoveChild),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ParentDashboardCubit>().removeChild(
        childId,
        surahId: widget.surahId,
      );
    }
  }

  Future<void> _showQuickRewardDialog(BuildContext context) async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.parentDashboardAddReward),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.parentDashboardRewardHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.parentDashboardAddReward),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty && context.mounted) {
      unawaited(context.read<ParentDashboardCubit>().addReward(title));
    }
  }

  Future<void> _showLastSessionDialog(
    BuildContext context,
    List<KidsSessionLog> logs,
  ) async {
    final latest = logs.isEmpty ? null : logs.first;
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.parentDashboardLastSession),
        content: Text(
          latest == null
              ? context.l10n.parentDashboardNoSessionsYet
              : context.l10n.parentDashboardSessionSummary(
                  latest.surahId,
                  latest.ayahNumber,
                  latest.repeatsCompleted,
                  latest.pointsEarned,
                ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.parentDashboardDone),
          ),
        ],
      ),
    );
  }
}

class _ParentDashboardBusy extends StatelessWidget {
  const _ParentDashboardBusy({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingWidget(),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePadding,
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinGate extends StatefulWidget {
  const _PinGate({
    required this.title,
    required this.buttonText,
    required this.controller,
    required this.onSubmit,
    this.requiresConfirmation = false,
    this.onReset,
  });

  final String title;
  final String buttonText;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final bool requiresConfirmation;
  final VoidCallback? onReset;

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = widget.controller.text.trim();
    final confirm = _confirmController.text.trim();
    if (widget.requiresConfirmation && pin != confirm) {
      setState(() => _error = context.l10n.parentDashboardPinMismatch);
      return;
    }
    setState(() => _error = null);
    widget.onSubmit(pin);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 54, color: Color(0xFF2D8E4C)),
            const SizedBox(height: AppSpacing.md),
            Text(widget.title, style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.parentDashboardPinHelp,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: widget.controller,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'PIN',
              ),
            ),
            if (widget.requiresConfirmation) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: context.l10n.parentDashboardPinConfirm,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.buttonText),
              ),
            ),
            if (widget.onReset != null)
              TextButton(
                onPressed: widget.onReset,
                child: Text(context.l10n.parentDashboardResetPin),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.dashboard,
    required this.onAddReward,
    required this.onShowLastLog,
  });

  final ParentDashboard dashboard;
  final VoidCallback onAddReward;
  final VoidCallback onShowLastLog;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toUtc();
    final todayStart = DateTime.utc(today.year, today.month, today.day);
    final todaysLogs = dashboard.logs
        .where((log) => !log.completedAt.toUtc().isBefore(todayStart))
        .toList();
    final points = todaysLogs.fold<int>(
      0,
      (sum, log) => sum + log.pointsEarned,
    );
    final sentence = todaysLogs.isEmpty
        ? context.l10n.parentDashboardTodayEmpty
        : context.l10n.parentDashboardTodayCompleted(todaysLogs.length);

    return _Panel(
      title: context.l10n.parentDashboardTodaySummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Metric(
                label: context.l10n.parentDashboardTodaySessions,
                value: '${todaysLogs.length}',
              ),
              _Metric(
                label: context.l10n.parentDashboardTodayPoints,
                value: '$points',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(sentence, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: onAddReward,
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: Text(context.l10n.parentDashboardAddReward),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: onShowLastLog,
                      icon: const Icon(Icons.history_rounded),
                      label: Text(context.l10n.parentDashboardShowLastSession),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAddReward,
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: Text(context.l10n.parentDashboardAddReward),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onShowLastLog,
                      icon: const Icon(Icons.history_rounded),
                      label: Text(context.l10n.parentDashboardShowLastSession),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.dashboard});
  final ParentDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final p = dashboard.progress;
    return _Panel(
      title: context.l10n.parentDashboardChildSummary,
      child: Column(
        children: [
          Row(
            children: [
              _Metric(
                label: context.l10n.parentDashboardPoints,
                value: '${p.totalPoints}',
              ),
              _Metric(
                label: context.l10n.parentDashboardStars,
                value: '${p.starsEarned}',
              ),
              _Metric(
                label: context.l10n.parentDashboardWeekSessions,
                value: '${dashboard.weeklyCompletedSessions}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value:
                (dashboard.weeklyCompletedSessions /
                        dashboard.settings.weeklyGoalSessions)
                    .clamp(0, 1),
            minHeight: 8,
            backgroundColor: const Color(0xFF2D8E4C).withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2D8E4C)),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.settings});
  final ParentSettings settings;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.parentDashboardChildReminder,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: settings.reminderEnabled,
        title: Text(context.l10n.parentDashboardDailyReminder),
        subtitle: Text(context.l10n.parentDashboardReminderSubtitle),
        onChanged: (value) =>
            context.read<ParentDashboardCubit>().updateReminder(
              enabled: value,
              hour: settings.reminderHour,
              minute: settings.reminderMinute,
            ),
      ),
    );
  }
}

class _RemoteToolsCard extends StatelessWidget {
  const _RemoteToolsCard({
    required this.children,
    required this.onScan,
    required this.onManual,
    required this.onAddReward,
    required this.onRemoveChild,
  });

  final List<RemoteChildSummary> children;
  final VoidCallback onScan;
  final VoidCallback onManual;
  final ValueChanged<String> onAddReward;
  final void Function(String childUserId, String displayName) onRemoveChild;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.parentDashboardRemoteFollowup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(context.l10n.parentDashboardScanQr),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: onManual,
                  child: Text(context.l10n.parentDashboardManualEntry),
                ),
              ),
            ],
          ),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(context.l10n.parentDashboardNoRemoteChild),
            )
          else
            ...children.map(
              (child) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.child_care_rounded),
                ),
                title: Text(child.displayName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.parentDashboardRemoteChildSummary(
                        child.progress.ayahsCompleted,
                        child.progress.totalPoints,
                      ),
                    ),
                    if (child.production case final production?) ...[
                      Text(
                        context.l10n.parentDashboardMemorizedSummary(
                          production.totalMemorizedAyahs,
                          production.totalAyahsTracked,
                          production.completionPercent.round(),
                        ),
                      ),
                      if (production.reviewsOverdue > 0 ||
                          production.reviewsCompleted > 0)
                        Text(
                          context.l10n.parentDashboardReviewsSummary(
                            production.reviewsCompleted,
                            production.reviewsOverdue,
                          ),
                        ),
                      if (production.dailyPlanTotal > 0)
                        Text(
                          context.l10n.dailyPlanProgressCount(
                            production.dailyPlanCompleted,
                            production.dailyPlanTotal,
                          ),
                        ),
                      if (production.currentStreak != null)
                        Text(
                          context.l10n.parentDashboardStreakSummary(
                            production.currentStreak!,
                          ),
                        ),
                      if (production.certificates.isNotEmpty)
                        Text(
                          context.l10n.parentDashboardCertificatesSummary(
                            production.certificates.length,
                          ),
                        ),
                    ],
                  ],
                ),
                isThreeLine: child.production != null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.card_giftcard_rounded),
                      onPressed: () => onAddReward(child.childUserId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link_off_rounded),
                      tooltip: context.l10n.parentDashboardRemoveChild,
                      onPressed: () =>
                          onRemoveChild(child.childUserId, child.displayName),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({
    required this.rewards,
    required this.controller,
    required this.onAdd,
  });

  final List<ParentReward> rewards;
  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.parentDashboardRewardsTitle,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: context.l10n.parentDashboardRewardHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onAdd,
                child: Text(context.l10n.parentDashboardAddReward),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (rewards.isEmpty)
            Text(context.l10n.parentDashboardRewardEmpty)
          else
            ...rewards.map(
              (reward) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  reward.status == ParentRewardStatus.locked
                      ? Icons.lock_rounded
                      : Icons.emoji_events_rounded,
                ),
                title: Text(reward.title),
                subtitle: Text(_rewardStatusLabel(context, reward.status)),
              ),
            ),
        ],
      ),
    );
  }

  String _rewardStatusLabel(BuildContext context, ParentRewardStatus status) =>
      switch (status) {
        ParentRewardStatus.locked => context.l10n.parentDashboardRewardLocked,
        ParentRewardStatus.unlocked =>
          context.l10n.parentDashboardRewardUnlocked,
        ParentRewardStatus.claimed => context.l10n.parentDashboardRewardClaimed,
      };
}

class _LogsCard extends StatelessWidget {
  const _LogsCard({required this.logs});
  final List<KidsSessionLog> logs;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: context.l10n.parentDashboardRecentSessions,
      child: logs.isEmpty
          ? Text(context.l10n.parentDashboardNoKidsSessions)
          : Column(
              children: logs.take(8).map((log) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2D8E4C),
                  ),
                  title: Text(
                    context.l10n.parentDashboardLogTitle(
                      log.surahId,
                      log.ayahNumber,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.parentDashboardLogSubtitle(
                      log.repeatsCompleted,
                      log.pointsEarned,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTypography.headlineSmall),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(fontFamily: 'Amiri'),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.parentDashboardScanChildCodeTitle),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          String? value;
          for (final barcode in capture.barcodes) {
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              value = barcode.rawValue;
              break;
            }
          }
          if (value == null || value.isEmpty) return;
          _done = true;
          Navigator.pop(context, value);
        },
      ),
    );
  }
}
