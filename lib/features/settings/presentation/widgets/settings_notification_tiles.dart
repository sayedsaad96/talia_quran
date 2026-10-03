import '../../../../core/utils/locale_number_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/notification_settings_cubit.dart';
import '../cubits/notification_settings_state.dart';
import 'settings_group.dart';
import 'settings_section.dart';

import '../../../../core/widgets/locale_time_picker.dart';

class NotificationSettingTile extends StatefulWidget {
  const NotificationSettingTile({super.key, required this.isDark, this.cubit});

  final bool isDark;
  final NotificationSettingsCubit? cubit;

  @override
  State<NotificationSettingTile> createState() =>
      _NotificationSettingTileState();
}

class _NotificationSettingTileState extends State<NotificationSettingTile>
    with WidgetsBindingObserver {
  static const _reviewKey = TaliaNotificationService.dailyReviewPreferenceKey;
  static const _streakKey = TaliaNotificationService.streakAlertPreferenceKey;
  static const _morningAzkarKey =
      TaliaNotificationService.morningAzkarPreferenceKey;
  static const _eveningAzkarKey =
      TaliaNotificationService.eveningAzkarPreferenceKey;
  static const _dailyDuaKey = TaliaNotificationService.dailyDuaPreferenceKey;
  static const _dailyAyahKey = TaliaNotificationService.dailyAyahPreferenceKey;
  static const _fridayKahfKey =
      TaliaNotificationService.fridayKahfPreferenceKey;
  static const _weeklyImpactKey =
      TaliaNotificationService.weeklyImpactPreferenceKey;
  static const _tahajjudKey = TaliaNotificationService.tahajjudPreferenceKey;
  static const _khatmahKey =
      TaliaNotificationService.khatmahReminderPreferenceKey;

  late final NotificationSettingsCubit _cubit;
  bool _ownsCubit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.cubit != null) {
      _cubit = widget.cubit!;
      _ownsCubit = false;
    } else if (getIt.isRegistered<NotificationSettingsCubit>()) {
      _cubit = getIt<NotificationSettingsCubit>()..load();
      _ownsCubit = true;
    } else {
      final prefs = getIt.isRegistered<SharedPreferences>()
          ? getIt<SharedPreferences>()
          : null;
      final service = getIt.isRegistered<TaliaNotificationService>()
          ? getIt<TaliaNotificationService>()
          : TaliaNotificationService();
      final scheduler = getIt.isRegistered<NotificationScheduler>()
          ? getIt<NotificationScheduler>()
          : null;

      if (prefs != null) {
        _cubit = NotificationSettingsCubit(prefs, service, scheduler)..load();
        _ownsCubit = true;
      } else {
        // Fallback for isolated widget tests without prefs initialized
        SharedPreferences.getInstance().then((p) {
          _cubit = NotificationSettingsCubit(p, service, scheduler)..load();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cubit.checkPermission();
    }
  }

  String _formatTime(TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    final formatted = localizations.formatTimeOfDay(
      time,
      alwaysUse24HourFormat: false,
    );
    if (context.isArabic) {
      return formatted.replaceAll('AM', 'ص').replaceAll('PM', 'م');
    }
    return formatted;
  }

  Future<void> _pickTime(String key, TimeOfDay initialTime) async {
    final l10n = context.l10n;
    final newTime = await showLocaleTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (newTime != null && newTime != initialTime) {
      await _cubit.updateReminderTime(key, newTime, l10n: l10n);
    }
  }

  Future<void> _pickQuietHour({
    required NotificationSettingsState state,
    required bool isStart,
  }) async {
    final l10n = context.l10n;
    final currentHour = isStart ? state.quietHoursStart : state.quietHoursEnd;
    final selected = await showLocaleTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
    );
    if (selected == null) return;
    await _cubit.updateQuietHours(
      startHour: isStart ? selected.hour : state.quietHoursStart,
      endHour: isStart ? state.quietHoursEnd : selected.hour,
      l10n: l10n,
    );
  }

  Widget _buildNotificationPreferences(
    NotificationSettingsState state,
    Color primary,
    Color textColor,
    Color subtextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.notificationQuietHours,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              context.l10n.notificationQuietHoursSub,
              style: AppTypography.bodySmall.copyWith(color: subtextColor),
            ),
            value: state.quietHoursEnabled,
            onChanged: (value) => _cubit.toggleReminder(
              TaliaNotificationService.quietHoursPreferenceKey,
              value,
              l10n: context.l10n,
            ),
            activeThumbColor: primary,
          ),
          if (state.quietHoursEnabled)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: AppSpacing.lg,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _pickQuietHour(state: state, isStart: true),
                    child: Text(
                      '${context.l10n.notificationQuietHoursStart}: '
                      '${_formatTime(TimeOfDay(hour: state.quietHoursStart, minute: 0))}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () =>
                        _pickQuietHour(state: state, isStart: false),
                    child: Text(
                      '${context.l10n.notificationQuietHoursEnd}: '
                      '${_formatTime(TimeOfDay(hour: state.quietHoursEnd, minute: 0))}',
                    ),
                  ),
                ],
              ),
            ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.notificationSmartReminder,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              context.l10n.notificationSmartReminderSub,
              style: AppTypography.bodySmall.copyWith(color: subtextColor),
            ),
            value: state.smartReminder,
            onChanged: (value) => _cubit.toggleReminder(
              TaliaNotificationService.smartReminderPreferenceKey,
              value,
              l10n: context.l10n,
            ),
            activeThumbColor: primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeEditorTile({
    required String title,
    required TimeOfDay time,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTapEdit,
    required IconData icon,
    required Color primaryColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    final effectiveOpacity = isEnabled ? 1.0 : 0.55;

    return AnimatedOpacity(
      opacity: effectiveOpacity,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isEnabled
                    ? primaryColor.withValues(alpha: 0.12)
                    : primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isEnabled ? primaryColor : subtextColor,
                size: 21,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: isEnabled ? onTapEdit : null,
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(
                      context.l10n.notificationEverydayAt(_formatTime(time)),
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isEnabled ? primaryColor : subtextColor,
                      backgroundColor: isEnabled
                          ? primaryColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(
                        color: isEnabled
                            ? primaryColor.withValues(alpha: 0.25)
                            : subtextColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(
              value: isEnabled,
              onChanged: onToggle,
              activeThumbColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;
    final primary = context.tokens.accent;

    return BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          previous.feedbackRevision != current.feedbackRevision,
      listener: (context, state) {
        final message = switch (state.feedback) {
          NotificationSettingsFeedback.saveFailed =>
            context.l10n.notificationSettingsSaveFailed,
          NotificationSettingsFeedback.schedulingFailed =>
            context.l10n.notificationSettingsSchedulingFailed,
          null => null,
        };
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        return Column(
          children: [
            if (state.isSystemPermissionBlocked)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(
                      alpha: widget.isDark ? 0.15 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              context.l10n.notificationPermissionBlockedTitle,
                              style: AppTypography.labelLarge.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.notificationPermissionBlockedBody,
                        style: AppTypography.bodySmall.copyWith(
                          color: subtextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: openAppSettings,
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: Text(
                            context.l10n.notificationOpenSystemSettings,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.warning,
                            side: const BorderSide(color: AppColors.warning),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Status Bar Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: widget.isDark ? 0.12 : 0.07),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: state.isSystemPermissionBlocked
                            ? AppColors.warning
                            : (state.enabledCount > 0
                                  ? AppColors.success
                                  : AppColors.warning),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.isSystemPermissionBlocked
                            ? context.l10n.notificationStatusBlocked
                            : context.l10n.notificationStatusSummary(
                                LocaleNumberFormatter.format(
                                  (state.enabledCount).toString(),
                                  context.l10n.localeName,
                                ),
                                LocaleNumberFormatter.format(
                                  (state.totalCount).toString(),
                                  context.l10n.localeName,
                                ),
                              ),
                        style: AppTypography.labelMedium.copyWith(
                          color: state.isSystemPermissionBlocked
                              ? AppColors.warning
                              : primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SettingsInListHeader(title: context.l10n.settingsRemindersGeneral),
            _buildNotificationPreferences(
              state,
              primary,
              textColor,
              subtextColor,
            ),
            SettingsInListHeader(
              title: context.l10n.settingsRemindersMemorization,
            ),
            _buildTimeEditorTile(
              title: context.l10n.dailyReviewReminder,
              time: state.dailyReviewTime,
              isEnabled: state.dailyReview,
              onToggle: (v) =>
                  _cubit.toggleReminder(_reviewKey, v, l10n: context.l10n),
              icon: Icons.auto_stories_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(_reviewKey, state.dailyReviewTime),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 2. Streak Protection Alert
            _buildTimeEditorTile(
              title: context.l10n.streakProtection,
              time: state.streakAlertTime,
              isEnabled: state.streakAlert,
              onToggle: (v) =>
                  _cubit.toggleReminder(_streakKey, v, l10n: context.l10n),
              icon: Icons.local_fire_department_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(_streakKey, state.streakAlertTime),
            ),
            SettingsInListHeader(title: context.l10n.settingsRemindersWorship),
            _buildTimeEditorTile(
              title: context.l10n.morningAzkarReminder,
              time: state.morningAzkarTime,
              isEnabled: state.morningAzkar,
              onToggle: (v) => _cubit.toggleReminder(
                _morningAzkarKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.wb_sunny_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () =>
                  _pickTime(_morningAzkarKey, state.morningAzkarTime),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 4. Evening Azkar Reminder
            _buildTimeEditorTile(
              title: context.l10n.eveningAzkarReminder,
              time: state.eveningAzkarTime,
              isEnabled: state.eveningAzkar,
              onToggle: (v) => _cubit.toggleReminder(
                _eveningAzkarKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.nightlight_round,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () =>
                  _pickTime(_eveningAzkarKey, state.eveningAzkarTime),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 5. Daily Dua Reminder
            _buildTimeEditorTile(
              title: context.l10n.dailyDuaReminder,
              time: state.dailyDuaTime,
              isEnabled: state.dailyDua,
              onToggle: (v) =>
                  _cubit.toggleReminder(_dailyDuaKey, v, l10n: context.l10n),
              icon: Icons.volunteer_activism_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(_dailyDuaKey, state.dailyDuaTime),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 6. Daily Ayah Reminder
            _buildTimeEditorTile(
              title: context.l10n.dailyAyahReminder,
              time: state.dailyAyahTime,
              isEnabled: state.dailyAyah,
              onToggle: (v) =>
                  _cubit.toggleReminder(_dailyAyahKey, v, l10n: context.l10n),
              icon: Icons.auto_awesome_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(_dailyAyahKey, state.dailyAyahTime),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 7. Friday Surah Al-Kahf Reminder
            _buildTimeEditorTile(
              title: context.l10n.notificationSettingsFridayKahf,
              time: state.fridayKahfTime,
              isEnabled: state.fridayKahf,
              onToggle: (v) =>
                  _cubit.toggleReminder(_fridayKahfKey, v, l10n: context.l10n),
              icon: Icons.menu_book_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(_fridayKahfKey, state.fridayKahfTime),
            ),
            SettingsDivider(isDark: widget.isDark),
            _buildTimeEditorTile(
              title: context.l10n.notificationSettingsTahajjud,
              time: state.tahajjudTime,
              isEnabled: state.tahajjud,
              onToggle: (v) =>
                  _cubit.toggleReminder(_tahajjudKey, v, l10n: context.l10n),
              icon: Icons.nights_stay_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(_tahajjudKey, state.tahajjudTime),
            ),

            // ── Progress & Achievements Section ──
            SettingsInListHeader(title: context.l10n.settingsRemindersProgress),
            _buildTimeEditorTile(
              title: context.l10n.notificationSettingsWeeklyImpact,
              time: state.weeklyImpactTime,
              isEnabled: state.weeklyImpact,
              onToggle: (v) => _cubit.toggleReminder(
                _weeklyImpactKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.insights_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () =>
                  _pickTime(_weeklyImpactKey, state.weeklyImpactTime),
            ),
            SettingsDivider(isDark: widget.isDark),

            // Khatmah Daily Progress Reminder
            _buildTimeEditorTile(
              title: context.l10n.notificationSettingsKhatmah,
              time: state.khatmahReminderTime,
              isEnabled: state.khatmahReminder,
              onToggle: (v) =>
                  _cubit.toggleReminder(_khatmahKey, v, l10n: context.l10n),
              icon: Icons.bookmark_added_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () =>
                  _pickTime(_khatmahKey, state.khatmahReminderTime),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 11. Interactive Test Button & Picker
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: InkWell(
                onTap: () => _showTestNotificationPicker(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.touch_app_rounded,
                          color: primary,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.notificationTestInteractiveTitle,
                              style: AppTypography.bodyMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.notificationTestInteractiveSubtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.send_rounded, size: 18, color: primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTestNotificationPicker(BuildContext context) async {
    final surface = context.tokens.card;
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Material(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bottomSheetContext.l10n.notificationTestPickerTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bottomSheetContext.l10n.notificationTestPickerSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      bottomSheetContext.l10n.notificationTestReviewTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      bottomSheetContext.l10n.notificationTestReviewBody,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      final wasShown = await _cubit.showTestNotification(
                        title:
                            bottomSheetContext.l10n.notificationTestReviewTitle,
                        body:
                            bottomSheetContext.l10n.notificationTestReviewBody,
                        type: 'review',
                      );
                      if (wasShown) {
                        _showTestSuccessSnackBar();
                      } else {
                        _showTestFailureSnackBar();
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.gold,
                    ),
                    title: Text(
                      bottomSheetContext.l10n.notificationTestStreakTitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      bottomSheetContext.l10n.notificationTestStreakBody,
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      final wasShown = await _cubit.showTestNotification(
                        title:
                            bottomSheetContext.l10n.notificationTestStreakTitle,
                        body:
                            bottomSheetContext.l10n.notificationTestStreakBody,
                        type: 'streak',
                      );
                      if (wasShown) {
                        _showTestSuccessSnackBar();
                      } else {
                        _showTestFailureSnackBar();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTestSuccessSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.notificationTestSuccess),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  void _showTestFailureSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.notificationTestFailed),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
