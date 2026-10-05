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
import '../../application/guardian_session_controller.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../../domain/entities/kids_qr_link_contract.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/family_dashboard_cubit.dart';
import '../widgets/family_child_name.dart';
import '../widgets/family_remote_status_banner.dart';
import '../widgets/guardian_session_scope.dart';
import '../widgets/kids_policy_controls.dart';
import 'child_detail_page.dart';

import '../../../../core/widgets/locale_time_picker.dart';

part 'family_dashboard_cards.dart';
part 'family_dashboard_access.dart';

class FamilyDashboardPage extends StatelessWidget {
  const FamilyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GuardianSessionScope(
      ownsSession: true,
      child: BlocProvider(
        create: (_) => getIt<FamilyDashboardCubit>()..load(),
        child: const _FamilyDashboardView(),
      ),
    );
  }
}

/// True while a guardian visits the dashboard on the child's own device.
bool _inGuardianSession() =>
    getIt.isRegistered<GuardianSessionController>() &&
    getIt<GuardianSessionController>().isActive;

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
          if (_inGuardianSession())
            TextButton.icon(
              key: const ValueKey('guardian-session-back-to-child'),
              icon: const Icon(Icons.child_care_rounded),
              label: Text(context.l10n.guardianSessionBackToChild),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : getIt<GuardianSessionController>().end(),
            ),
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
      FamilyDashboardFeedbackType.rewardUnlocked =>
        l10n.parentRewardUnlockedFeedback,
      FamilyDashboardFeedbackType.rewardApproved =>
        l10n.parentRewardApprovedFeedback,
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
    // Linking another child needs the guardian's own account and device.
    final canAddChild = !_inGuardianSession();
    return RefreshIndicator(
      onRefresh: () => context.read<FamilyDashboardCubit>().refresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FamilyRemoteStatusBanner(
              status: dashboard.remoteStatus,
              fetchedAt: dashboard.remoteFetchedAt,
              onRetry: () => context.read<FamilyDashboardCubit>().refresh(),
            ),
          ),

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
          // A failed read is not "no children": the banner explains it and
          // the add-child tile stays reachable.
          if (!dashboard.hasAnyChild && !dashboard.remoteReadFailed)
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < dashboard.children.length) {
                      return _ChildCard(child: dashboard.children[index]);
                    }
                    // Last tile = "Add child" button
                    return _AddChildCard();
                  },
                  childCount: dashboard.children.length + (canAddChild ? 1 : 0),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
