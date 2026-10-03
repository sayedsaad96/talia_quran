import '../../../../core/utils/locale_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/entities/kids_qr_link_contract.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/family_dashboard_cubit.dart';
import '../widgets/kids_policy_controls.dart';
import 'child_detail_page.dart';

import '../../../../core/widgets/locale_time_picker.dart';

class FamilyDashboardPage extends StatelessWidget {
  const FamilyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FamilyDashboardCubit>()..load(),
      child: const _FamilyDashboardView(),
    );
  }
}

class _FamilyDashboardView extends StatefulWidget {
  const _FamilyDashboardView();

  @override
  State<_FamilyDashboardView> createState() => _FamilyDashboardViewState();
}

class _FamilyDashboardViewState extends State<_FamilyDashboardView> {
  final _pinController = TextEditingController();
  int _lastShownFeedbackEventId = 0;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.familyDashboardTitle,
          style: AppTypography.titleLarge,
        ),
        leading: IconButton(
          icon: const BackButtonIcon(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          BlocBuilder<FamilyDashboardCubit, FamilyDashboardState>(
            builder: (context, state) {
              if (state is FamilyDashboardLoaded) {
                return IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  tooltip: context.l10n.settings,
                  onPressed: () =>
                      _showSettingsSheet(context, state.dashboard.settings),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<FamilyDashboardCubit, FamilyDashboardState>(
        listener: (context, state) {
          // A fresh PIN prompt must not show digits typed for the old PIN.
          if (state is FamilyDashboardNeedsPin && state.feedback == null) {
            _pinController.clear();
          }
          final feedbackEventId = switch (state) {
            FamilyDashboardNeedsPin(:final feedbackEventId) => feedbackEventId,
            FamilyDashboardLocked(:final feedbackEventId) => feedbackEventId,
            FamilyDashboardLoaded(:final feedbackEventId) => feedbackEventId,
            _ => 0,
          };
          final feedback = switch (state) {
            FamilyDashboardNeedsPin(:final feedback) => feedback,
            FamilyDashboardLocked(:final feedback) => feedback,
            FamilyDashboardLoaded(:final feedback) => feedback,
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
          if (state is FamilyDashboardLoading ||
              state is FamilyDashboardInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is FamilyDashboardError) {
            return ErrorStateWidget(
              message: context.localizedCubitMessage(state.message),
              onRetry: () => context.read<FamilyDashboardCubit>().load(),
            );
          }
          if (state is FamilyDashboardNeedsPin) {
            return _PinGate(
              title: context.l10n.parentDashboardCreatePinTitle,
              buttonText: context.l10n.parentDashboardSavePinButton,
              controller: _pinController,
              requiresConfirmation: true,
              onSubmit: (pin) =>
                  context.read<FamilyDashboardCubit>().setPin(pin),
            );
          }
          if (state is FamilyDashboardLocked) {
            final recoveryEmail = context
                .read<FamilyDashboardCubit>()
                .recoveryAccountEmail;
            return _PinGate(
              title: context.l10n.parentDashboardEnterPinTitle,
              buttonText: context.l10n.parentDashboardEnterButton,
              controller: _pinController,
              onSubmit: (pin) =>
                  context.read<FamilyDashboardCubit>().unlock(pin),
              onForgot: recoveryEmail == null
                  ? null
                  : () => _recoverForgottenPin(context, recoveryEmail),
            );
          }
          if (state is FamilyDashboardLoaded) {
            return _FamilyLoadedBody(dashboard: state.dashboard);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _feedbackMessage(
    BuildContext context,
    FamilyDashboardFeedback feedback,
  ) {
    final l10n = context.l10n;
    return switch (feedback.type) {
      FamilyDashboardFeedbackType.pinInvalid => l10n.parentDashboardPinInvalid,
      FamilyDashboardFeedbackType.pinIncorrect =>
        l10n.parentDashboardPinIncorrect,
      FamilyDashboardFeedbackType.pinMismatch =>
        l10n.parentDashboardPinMismatch,
      FamilyDashboardFeedbackType.childRemoved =>
        l10n.parentDashboardChildRemoved,
      FamilyDashboardFeedbackType.nicknameSaved =>
        l10n.familyDashboardNicknameSaved,
      FamilyDashboardFeedbackType.childIdentitySaved => l10n.childIdentitySaved,
      FamilyDashboardFeedbackType.childLinked =>
        l10n.parentDashboardChildLinked,
      FamilyDashboardFeedbackType.rewardAdded =>
        l10n.parentDashboardRewardAdded,
      FamilyDashboardFeedbackType.remoteRewardAdded =>
        l10n.parentDashboardRemoteRewardAdded,
      FamilyDashboardFeedbackType.reminderSaved =>
        l10n.parentDashboardReminderSaved,
      FamilyDashboardFeedbackType.accountPasswordIncorrect =>
        l10n.parentDashboardAccountPasswordIncorrect,
      FamilyDashboardFeedbackType.accountCheckUnavailable =>
        l10n.parentDashboardAccountCheckUnavailable,
      FamilyDashboardFeedbackType.failure => context.localizedCubitMessage(
        feedback.message ?? CubitMessageCodes.errorUnknown,
      ),
    };
  }

  Future<void> _recoverForgottenPin(BuildContext context, String email) async {
    final cubit = context.read<FamilyDashboardCubit>();
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _ForgotPinDialog(email: email),
    );
    if (password == null || password.isEmpty) return;
    await cubit.resetForgottenPin(password);
  }

  Future<void> _confirmChangePin(BuildContext context) async {
    final cubit = context.read<FamilyDashboardCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.parentDashboardChangePin),
        content: Text(context.l10n.parentDashboardChangePinConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.resetAccess();
  }

  void _showSettingsSheet(BuildContext context, ParentSettings settings) {
    // The sheet builder's context sits above the BlocProvider.value below,
    // so the controls use the dashboard's cubit captured here.
    final dashboardCubit = context.read<FamilyDashboardCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<FamilyDashboardCubit>(),
        child: Material(
          color: context.tokens.background,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.kidsJourneyBetaTitle,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  title: Text(context.l10n.kidsJourneyBetaTitle),
                  subtitle: Text(context.l10n.kidsJourneyBetaDescription),
                  value: settings.kidsHifzV2Enabled,
                  onChanged: (value) async {
                    await dashboardCubit.saveSettings(
                      settings.copyWith(kidsHifzV2Enabled: value),
                    );
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                // The "guidance audio" switch stays intentionally absent
                // until the kids session consumes the setting (K10 in
                // docs/audits/TALIA_KIDS_PATH_REVIEW_REPORT.md). ParentSettings
                // keeps the stored value so nothing is lost meanwhile.
                // Policy fields (incl. the session goal) save through the
                // policy path: CAS when this device is linked, else local.
                KidsPolicyControls(
                  policy: KidsChildPolicy.fromSettings(settings),
                  onChanged: (policy) async {
                    await dashboardCubit.saveChildPolicy(policy);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                const Divider(),
                Text(
                  context.l10n.parentDashboardReminders,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  title: Text(context.l10n.parentDashboardDailyReminder),
                  subtitle: Text(
                    settings.reminderEnabled
                        ? context.digitText(
                            '${settings.reminderHour}:${settings.reminderMinute.toString().padLeft(2, '0')}',
                          )
                        : context.l10n.parentDashboardNotSet,
                  ),
                  value: settings.reminderEnabled,
                  onChanged: (val) async {
                    final cubit = dashboardCubit;
                    final l10n = sheetContext.l10n;
                    if (val) {
                      final time = await showLocaleTimePicker(
                        context: sheetContext,
                        initialTime: TimeOfDay(
                          hour: settings.reminderHour,
                          minute: settings.reminderMinute,
                        ),
                      );
                      if (time != null && sheetContext.mounted) {
                        await cubit.saveSettings(
                          settings.copyWith(
                            reminderEnabled: true,
                            reminderHour: time.hour,
                            reminderMinute: time.minute,
                          ),
                        );
                        await getIt<NotificationScheduler>()
                            .refreshNotifications(l10n);
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      }
                    } else {
                      await cubit.saveSettings(
                        settings.copyWith(reminderEnabled: false),
                      );
                      await getIt<NotificationScheduler>().refreshNotifications(
                        l10n,
                      );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmChangePin(context);
                    },
                    child: Text(context.l10n.parentDashboardChangePin),
                  ),
                ),
                SizedBox(
                  height:
                      MediaQuery.paddingOf(sheetContext).bottom + AppSpacing.md,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Loaded body ──────────────────────────────────────────────────────────────

class _FamilyLoadedBody extends StatelessWidget {
  const _FamilyLoadedBody({required this.dashboard});
  final FamilyDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FamilyDashboardCubit>().refresh(),
      child: CustomScrollView(
        slivers: [
          // ─── Family summary banner ───────────────────────────────────────
          if (dashboard.hasAnyChild)
            SliverToBoxAdapter(
              child: _FamilySummaryBanner(dashboard: dashboard),
            ),

          // ─── Section label ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                AppSpacing.sm,
              ),
              child: Text(
                context.l10n.familyDashboardMyChildren,
                style: AppTypography.titleMedium,
              ),
            ),
          ),

          // ─── Children grid ───────────────────────────────────────────────
          if (!dashboard.hasAnyChild)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyFamilyPlaceholder(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < dashboard.children.length) {
                    return _ChildCard(child: dashboard.children[index]);
                  }
                  // Last tile = "Add child" button
                  return _AddChildCard();
                }, childCount: dashboard.children.length + 1),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

// ─── Family summary banner ────────────────────────────────────────────────────

class _FamilySummaryBanner extends StatelessWidget {
  const _FamilySummaryBanner({required this.dashboard});
  final FamilyDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final activeCount = dashboard.totalActiveToday;
    final totalPoints = dashboard.totalPointsToday;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1A6B38)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.family_restroom_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.familyDashboardTodaySummaryTitle,
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.familyDashboardTodaySummary(
                    LocaleNumberFormatter.format(
                      (activeCount).toString(),
                      context.l10n.localeName,
                    ),
                    LocaleNumberFormatter.format(
                      (totalPoints).toString(),
                      context.l10n.localeName,
                    ),
                  ),
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

// ─── Child card ───────────────────────────────────────────────────────────────

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});
  final FamilyChildEntry child;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final cardColor = context.tokens.card;
    final isActive = child.isActiveToday;

    return Semantics(
      label:
          '${child.displayName}${isActive ? ' — ${context.l10n.familyDashboardChildActiveToday(LocaleNumberFormatter.format((child.todayPoints).toString(), context.l10n.localeName))}' : ''}',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: () => context.push(
          AppRoutes.childDetail,
          extra: ChildDetailRouteArgs(
            child: child,
            cubit: context.read<FamilyDashboardCubit>(),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar + active indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      child.avatarEmoji ?? (child.isLocal ? '👨‍👧' : '🧒'),
                      style: AppTypography.headlineLarge,
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Name
              Text(
                child.displayName,
                style: AppTypography.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (child.childAge case final age?)
                Text(
                  context.l10n.childAgeYears(
                    age,
                    LocaleNumberFormatter.format(
                      (age).toString(),
                      context.l10n.localeName,
                    ),
                  ),
                  style: AppTypography.labelSmall.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              // Local badge
              if (child.isLocal) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    context.l10n.familyDashboardLocalBadge,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Level progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.kidsLevelValue(
                          LocaleNumberFormatter.format(
                            (child.currentLevel).toString(),
                            context.l10n.localeName,
                          ),
                        ),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (child.currentStreak > 0)
                        Text(
                          '🔥 ${child.currentStreak}',
                          style: AppTypography.labelSmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    child: LinearProgressIndicator(
                      value: child.levelProgress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(
                        0xFF0D5C53,
                      ).withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActive
                        ? context.l10n.familyDashboardChildActiveToday(
                            LocaleNumberFormatter.format(
                              (child.todayPoints).toString(),
                              context.l10n.localeName,
                            ),
                          )
                        : context.l10n.familyDashboardChildNoActivity,
                    style: AppTypography.labelSmall.copyWith(
                      color: isActive
                          ? AppColors.primary
                          : context.tokens.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add child card ───────────────────────────────────────────────────────────

class _AddChildCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      onTap: () => _showAddChildOptions(context),
      child: Container(
        decoration: BoxDecoration(
          color: context.tokens.card,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                context.l10n.familyDashboardAddChild,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty placeholder ────────────────────────────────────────────────────────

class _EmptyFamilyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.family_restroom_rounded,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.familyDashboardNoChildren,
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.familyDashboardNoChildrenHint,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => _showAddChildOptions(context),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(context.l10n.familyDashboardAddChild),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PIN Gate (reused from parent dashboard) ──────────────────────────────────

class _PinGate extends StatefulWidget {
  const _PinGate({
    required this.title,
    required this.buttonText,
    required this.controller,
    required this.onSubmit,
    this.requiresConfirmation = false,
    this.onForgot,
  });

  final String title;
  final String buttonText;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final bool requiresConfirmation;
  final VoidCallback? onForgot;

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
            const Icon(Icons.lock_rounded, size: 54, color: AppColors.primary),
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
              Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: Text(widget.buttonText),
              ),
            ),
            if (widget.onForgot != null)
              TextButton(
                onPressed: widget.onForgot,
                child: Text(context.l10n.parentDashboardForgotPin),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Forgotten PIN ────────────────────────────────────────────────────────────

class _ForgotPinDialog extends StatefulWidget {
  const _ForgotPinDialog({required this.email});
  final String email;

  @override
  State<_ForgotPinDialog> createState() => _ForgotPinDialogState();
}

class _ForgotPinDialogState extends State<_ForgotPinDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _controller.text;
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.parentDashboardForgotPinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.parentDashboardForgotPinBody(widget.email)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(labelText: context.l10n.password),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.l10n.parentDashboardForgotPinConfirm),
        ),
      ],
    );
  }
}

// ─── Add Child Logic ──────────────────────────────────────────────────────────

void _showAddChildOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Material(
      color: context.tokens.background,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.familyDashboardAddChild,
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.familyDashboardNoChildrenHint,
              style: AppTypography.bodySmall.copyWith(
                color: context.tokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primary,
              ),
              title: Text(context.l10n.parentDashboardScanQr),
              onTap: () {
                Navigator.pop(sheetContext);
                _openScanner(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.keyboard_rounded,
                color: AppColors.primary,
              ),
              title: Text(context.l10n.parentDashboardEnterLinkingCode),
              onTap: () {
                Navigator.pop(sheetContext);
                _showManualTokenDialog(context);
              },
            ),
            SizedBox(height: MediaQuery.paddingOf(sheetContext).bottom),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openScanner(BuildContext context) async {
  final token = await Navigator.of(
    context,
  ).push<String>(MaterialPageRoute(builder: (_) => const _QrScannerPage()));
  if (token != null && context.mounted) {
    await context.read<FamilyDashboardCubit>().acceptRemoteToken(token);
  }
}

Future<void> _showManualTokenDialog(BuildContext context) async {
  final token = await showDialog<String>(
    context: context,
    builder: (_) => const _ManualTokenDialog(),
  );
  if (token != null && token.isNotEmpty && context.mounted) {
    await context.read<FamilyDashboardCubit>().acceptRemoteToken(token);
  }
}

class _ManualTokenDialog extends StatefulWidget {
  const _ManualTokenDialog();

  @override
  State<_ManualTokenDialog> createState() => _ManualTokenDialogState();
}

class _ManualTokenDialogState extends State<_ManualTokenDialog> {
  late final TextEditingController _controller;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.parentDashboardEnterLinkingCode),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.parentDashboardLinkHint,
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(context.l10n.parentDashboardLinkAction),
        ),
      ],
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();
  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.parentDashboardScanQr)),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final raw = barcode.rawValue;
            if (raw == null) continue;
            // Accept the shared kids-link contract payload (and the legacy
            // prefix) instead of a hard-coded literal that drifted from the
            // child-side generator and silently broke QR pairing.
            if (!KidsQrLinkContract.isLinkPayload(raw)) continue;
            Navigator.pop(context, KidsQrLinkContract.extractToken(raw));
            break;
          }
        },
      ),
    );
  }
}
