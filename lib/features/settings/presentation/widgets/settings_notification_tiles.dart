import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/adhan_preview_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/prayer_sound.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/notification_settings_cubit.dart';
import '../cubits/notification_settings_state.dart';
import 'settings_group.dart';
import 'settings_section.dart';

class NotificationSettingTile extends StatefulWidget {
  const NotificationSettingTile({
    super.key,
    required this.isDark,
    this.cubit,
  });

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
  static const _tahajjudKey =
      TaliaNotificationService.tahajjudPreferenceKey;
  static const _khatmahKey =
      TaliaNotificationService.khatmahReminderPreferenceKey;
  static const _prayerTimesKey =
      TaliaNotificationService.prayerNotificationsPreferenceKey;
  static const _prayerFajrKey = TaliaNotificationService.prayerFajrKey;
  static const _prayerDhuhrKey = TaliaNotificationService.prayerDhuhrKey;
  static const _prayerAsrKey = TaliaNotificationService.prayerAsrKey;
  static const _prayerMaghribKey = TaliaNotificationService.prayerMaghribKey;
  static const _prayerIshaKey = TaliaNotificationService.prayerIshaKey;

  final AdhanPreviewService _previewService = AdhanPreviewService();
  static const _prayerAthanKey = TaliaNotificationService.prayerAthanKey;

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

  Future<void> _pickTime(
    String key,
    TimeOfDay initialTime,
  ) async {
    final l10n = context.l10n;
    final newTime = await showTimePicker(
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
    final currentHour = isStart
        ? state.quietHoursStart
        : state.quietHoursEnd;
    final selected = await showTimePicker(
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
                    onPressed: () => _pickQuietHour(
                      state: state,
                      isStart: true,
                    ),
                    child: Text(
                      '${context.l10n.notificationQuietHoursStart}: '
                      '${_formatTime(TimeOfDay(hour: state.quietHoursStart, minute: 0))}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => _pickQuietHour(
                      state: state,
                      isStart: false,
                    ),
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

  Widget _buildPrayerTimesTile({
    required NotificationSettingsState state,
    required Color primary,
    required Color textColor,
    required Color subtextColor,
  }) {
    // V2 §27: prayer notifications are the SECOND master switch. The first
    // one (`prayer_times_enabled`, prayer page) must be ON first — otherwise
    // this switch renders disabled with an explanation instead of a scary
    // dead toggle.
    final prayerTimesService = getIt.isRegistered<PrayerTimesService>()
        ? getIt<PrayerTimesService>()
        : null;
    final prayerTimesEnabled = prayerTimesService?.isEnabled ?? false;
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          secondary: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mosque_rounded,
              color: primary,
              size: 22,
            ),
          ),
          title: Text(
            context.l10n.notificationSettingsPrayerTimes,
            style: AppTypography.bodyMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            prayerTimesEnabled
                ? context.l10n.notificationSettingsPrayerTimesSub
                : context.l10n.notificationSettingsPrayerNeedsTimes,
            style: AppTypography.bodySmall.copyWith(
              color: prayerTimesEnabled ? subtextColor : primary,
              fontWeight: prayerTimesEnabled ? null : FontWeight.w600,
            ),
          ),
          value: state.prayerNotifications,
          onChanged: prayerTimesEnabled
              ? (v) => _cubit.toggleReminder(
                  _prayerTimesKey,
                  v,
                  l10n: context.l10n,
                )
              : null,
          activeThumbColor: primary,
        ),
        if (state.prayerNotifications && prayerTimesEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildPrayerChip(
                  label: context.l10n.prayerFajr,
                  value: state.prayerFajr,
                  onChanged: (v) => _cubit.togglePrayer(
                    _prayerFajrKey,
                    v,
                    l10n: context.l10n,
                  ),
                  primary: primary,
                ),
                _buildPrayerChip(
                  label: context.l10n.prayerDhuhr,
                  value: state.prayerDhuhr,
                  onChanged: (v) => _cubit.togglePrayer(
                    _prayerDhuhrKey,
                    v,
                    l10n: context.l10n,
                  ),
                  primary: primary,
                ),
                _buildPrayerChip(
                  label: context.l10n.prayerAsr,
                  value: state.prayerAsr,
                  onChanged: (v) => _cubit.togglePrayer(
                    _prayerAsrKey,
                    v,
                    l10n: context.l10n,
                  ),
                  primary: primary,
                ),
                _buildPrayerChip(
                  label: context.l10n.prayerMaghrib,
                  value: state.prayerMaghrib,
                  onChanged: (v) => _cubit.togglePrayer(
                    _prayerMaghribKey,
                    v,
                    l10n: context.l10n,
                  ),
                  primary: primary,
                ),
                _buildPrayerChip(
                  label: context.l10n.prayerIsha,
                  value: state.prayerIsha,
                  onChanged: (v) => _cubit.togglePrayer(
                    _prayerIshaKey,
                    v,
                    l10n: context.l10n,
                  ),
                  primary: primary,
                ),
              ],
            ),
          ),
        if (state.prayerNotifications && prayerTimesEnabled)
          SwitchListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xl,
              end: AppSpacing.md,
            ),
            title: Text(
              context.l10n.notificationSettingsPrayerAthan,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              context.l10n.notificationSettingsPrayerAthanSub,
              style: AppTypography.bodySmall.copyWith(color: subtextColor),
            ),
            value: state.prayerAthan,
            onChanged: (v) => _cubit.toggleReminder(
              _prayerAthanKey,
              v,
              l10n: context.l10n,
            ),
            activeThumbColor: primary,
          ),
        if (state.prayerNotifications && prayerTimesEnabled && state.prayerAthan)
          _buildMuezzinTile(
            context,
            state,
            primary,
            textColor,
            subtextColor,
          ),
        if (Platform.isAndroid && state.prayerNotifications && prayerTimesEnabled)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xl,
              end: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // V2 §26: explanation first, then the opt-in button — and a
                  // soft, non-scary fallback message when denied.
                  Text(
                    context.l10n.notificationExactAlarmExplanation,
                    style: AppTypography.bodySmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OutlinedButton.icon(
                onPressed: () async {
                  final granted =
                      await _cubit.requestExactPrayerTimePermission();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        granted
                            ? context.l10n.notificationExactAlarmGranted
                            : context.l10n.notificationExactAlarmDenied,
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.alarm_rounded, size: 16),
                label: Text(
                  context.l10n.notificationExactAlarmRequest,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String get _selectedMuezzinId {
    final stored = _cubit.prefs.getString(
      TaliaNotificationService.prayerMuezzinKey,
    );
    final id = (stored == null || stored.isEmpty)
        ? MuezzinCatalog.defaultId
        : stored;
    return MuezzinCatalog.isSupported(id) ? id : MuezzinCatalog.defaultId;
  }

  String get _selectedFajrMuezzinId {
    final stored = _cubit.prefs.getString(
      TaliaNotificationService.prayerMuezzinFajrKey,
    );
    final id = stored ?? '';
    return (id.isEmpty || MuezzinCatalog.isSupported(id)) ? id : '';
  }

  /// Muezzin selection rows, shown under the "Full Adhan" switch.
  Widget _buildMuezzinTile(
    BuildContext context,
    NotificationSettingsState state,
    Color primary,
    Color textColor,
    Color subtextColor,
  ) {
    final l10n = context.l10n;
    final muezzin = MuezzinCatalog.byId(_selectedMuezzinId);
    final fajrOverride = _selectedFajrMuezzinId.isNotEmpty
        ? MuezzinCatalog.byId(_selectedFajrMuezzinId)
        : null;
    final subtitle = fajrOverride == null
        ? muezzin?.name(l10n.localeName) ?? l10n.muezzinDefault
        : l10n.muezzinFajrSummary(
            muezzin?.name(l10n.localeName) ?? l10n.muezzinDefault,
            fajrOverride.name(l10n.localeName),
          );
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xl,
        end: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.graphic_eq_rounded, color: primary, size: 22),
            title: Text(
              l10n.muezzinPickerTitle,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(color: subtextColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 22,
            ),
            onTap: () => _openMuezzinPicker(context, primary),
          ),
        ],
      ),
    );
  }

  Future<void> _openMuezzinPicker(BuildContext context, Color primary) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _MuezzinPickerSheet(
        initialMuezzinId: _selectedMuezzinId,
        initialFajrMuezzinId: _selectedFajrMuezzinId,
        primary: primary,
        previewService: _previewService,
      ),
    );
    // Stop preview if the sheet was dismissed mid-playback.
    await _previewService.stop();
  }

  Widget _buildPrayerChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primary,
  }) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: primary.withValues(alpha: 0.18),
      checkmarkColor: primary,
      labelStyle: AppTypography.labelSmall.copyWith(
        color: value ? primary : null,
        fontWeight: value ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;

    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      bloc: _cubit,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                state.enabledCount,
                                state.totalCount,
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
              onToggle: (v) => _cubit.toggleReminder(
                _reviewKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.auto_stories_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(
                _reviewKey,
                state.dailyReviewTime,
              ),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 2. Streak Protection Alert
            _buildTimeEditorTile(
              title: context.l10n.streakProtection,
              time: state.streakAlertTime,
              isEnabled: state.streakAlert,
              onToggle: (v) => _cubit.toggleReminder(
                _streakKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.local_fire_department_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(
                _streakKey,
                state.streakAlertTime,
              ),
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
              onTapEdit: () => _pickTime(
                _morningAzkarKey,
                state.morningAzkarTime,
              ),
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
              onTapEdit: () => _pickTime(
                _eveningAzkarKey,
                state.eveningAzkarTime,
              ),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 5. Daily Dua Reminder
            _buildTimeEditorTile(
              title: context.l10n.dailyDuaReminder,
              time: state.dailyDuaTime,
              isEnabled: state.dailyDua,
              onToggle: (v) => _cubit.toggleReminder(
                _dailyDuaKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.volunteer_activism_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(
                _dailyDuaKey,
                state.dailyDuaTime,
              ),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 6. Daily Ayah Reminder
            _buildTimeEditorTile(
              title: context.l10n.dailyAyahReminder,
              time: state.dailyAyahTime,
              isEnabled: state.dailyAyah,
              onToggle: (v) => _cubit.toggleReminder(
                _dailyAyahKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.auto_awesome_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(
                _dailyAyahKey,
                state.dailyAyahTime,
              ),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 7. Friday Surah Al-Kahf Reminder
            _buildTimeEditorTile(
              title: context.l10n.notificationSettingsFridayKahf,
              time: state.fridayKahfTime,
              isEnabled: state.fridayKahf,
              onToggle: (v) => _cubit.toggleReminder(
                _fridayKahfKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.menu_book_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(
                _fridayKahfKey,
                state.fridayKahfTime,
              ),
            ),
            SettingsDivider(isDark: widget.isDark),
            _buildTimeEditorTile(
              title: context.l10n.notificationSettingsTahajjud,
              time: state.tahajjudTime,
              isEnabled: state.tahajjud,
              onToggle: (v) => _cubit.toggleReminder(
                _tahajjudKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.nights_stay_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(
                _tahajjudKey,
                state.tahajjudTime,
              ),
            ),
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
              onTapEdit: () => _pickTime(
                _weeklyImpactKey,
                state.weeklyImpactTime,
              ),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 9. Khatmah Daily Progress Reminder
            _buildTimeEditorTile(
              title: context.l10n.notificationSettingsKhatmah,
              time: state.khatmahReminderTime,
              isEnabled: state.khatmahReminder,
              onToggle: (v) => _cubit.toggleReminder(
                _khatmahKey,
                v,
                l10n: context.l10n,
              ),
              icon: Icons.bookmark_added_rounded,
              primaryColor: primary,
              textColor: textColor,
              subtextColor: subtextColor,
              onTapEdit: () => _pickTime(
                _khatmahKey,
                state.khatmahReminderTime,
              ),
            ),
            SettingsDivider(isDark: widget.isDark),

            // 10. Prayer Times Reminders & Per-Prayer Filters
            _buildPrayerTimesTile(
              state: state,
              primary: primary,
              textColor: textColor,
              subtextColor: subtextColor,
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
    final surface = widget.isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

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
                    bottomSheetContext.isArabic
                        ? 'اختر نوع الإشعار التفاعلي للتجربة'
                        : 'Select notification type to test',
                    style: AppTypography.titleMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bottomSheetContext.isArabic
                        ? 'سيصلك إشعار تحفيزي فوري يحتوي على أزرار التفاعل المباشرة'
                        : 'You will receive an encouraging notification with action buttons',
                    style: AppTypography.bodySmall.copyWith(color: subtextColor),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      bottomSheetContext.isArabic ? 'جاهز نراجع سوا؟ 📖' : 'Daily Review 📖',
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      bottomSheetContext.isArabic
                          ? 'عندك 5 آيات مستنية مراجعتك النهاردة.. يلا خطوة بخطوة! ✨'
                          : 'You have 5 ayahs due for review today ⚡',
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      final wasShown = await _cubit.showTestNotification(
                        title: bottomSheetContext.isArabic
                            ? 'جاهز نراجع سوا؟ 📖'
                            : 'Daily Review Time 📖',
                        body: bottomSheetContext.isArabic
                            ? 'عندك 5 آيات مستنية مراجعتك النهاردة.. يلا خطوة بخطوة! ✨'
                            : 'You have 5 ayahs due for review today ⚡',
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
                      color: AppColors.amber,
                    ),
                    title: Text(
                      bottomSheetContext.isArabic
                          ? '⚠️ متضيعش إنجاز 7 أيام!'
                          : 'Streak Protection 🔥',
                      style: AppTypography.bodyMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      bottomSheetContext.isArabic
                          ? 'فاضل تكة صغيرة وتكمل وردك النهاردة.. متكسلش، تقدر تعملها! 🔥'
                          : "You haven't reviewed today — protect your streak now 🔥",
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      final wasShown = await _cubit.showTestNotification(
                        title: bottomSheetContext.isArabic
                            ? '⚠️ متضيعش إنجاز 7 أيام!'
                            : "⚠️ Don't lose 7 days streak!",
                        body: bottomSheetContext.isArabic
                            ? 'فاضل تكة صغيرة وتكمل وردك النهاردة.. متكسلش، تقدر تعملها! 🔥'
                            : "You haven't reviewed today — protect your streak now 🔥",
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
        content: Text(
          context.isArabic
              ? 'تم إرسال الإشعار التفاعلي بنجاح ✨'
              : 'Interactive test notification sent successfully ✨',
        ),
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
        content: Text(
          context.l10n.notificationTestFailed,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Bottom-sheet muezzin picker: radio list of the bundled adhan recordings
/// with an inline preview button per option, plus an optional Fajr-only
/// override selector. Committing a choice persists it through the cubit,
/// which reschedules prayer events immediately.
class _MuezzinPickerSheet extends StatefulWidget {
  const _MuezzinPickerSheet({
    required this.initialMuezzinId,
    required this.initialFajrMuezzinId,
    required this.primary,
    required this.previewService,
  });

  final String initialMuezzinId;
  final String initialFajrMuezzinId;
  final Color primary;
  final AdhanPreviewService previewService;

  @override
  State<_MuezzinPickerSheet> createState() => _MuezzinPickerSheetState();
}

class _MuezzinPickerSheetState extends State<_MuezzinPickerSheet> {
  late String _muezzinId = widget.initialMuezzinId;
  late String _fajrMuezzinId = widget.initialFajrMuezzinId;
  String? _previewingId;

  @override
  void dispose() {
    // Safety net: never leave audio running after the sheet closes.
    widget.previewService.stop();
    super.dispose();
  }

  Future<void> _togglePreview(String id) async {
    final service = widget.previewService;
    if (_previewingId == id) {
      setState(() => _previewingId = null);
      await service.stop();
      return;
    }
    setState(() => _previewingId = id);
    final started = await service.start(id);
    if (!mounted) return;
    if (!started) {
      setState(() => _previewingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtext = Theme.of(context).textTheme.bodySmall?.color;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: subtext?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.muezzinPickerTitle,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.muezzinPickerSubtitle,
              style: AppTypography.bodySmall.copyWith(color: subtext),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    RadioGroup<String>(
                      groupValue: _muezzinId,
                      onChanged: (value) => setState(() {
                        if (value != null) _muezzinId = value;
                      }),
                      child: Column(
                        children: [
                          for (final muezzin in MuezzinCatalog.all)
                            _buildRow(
                              context: context,
                              id: muezzin.id,
                              title: muezzin.name(l10n.localeName),
                              subtitle: muezzin.origin(l10n.localeName),
                              isFajrSection: false,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.muezzinFajrSectionTitle,
                        style: AppTypography.labelLarge.copyWith(
                          color: widget.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    RadioGroup<String>(
                      groupValue: _fajrMuezzinId,
                      onChanged: (value) =>
                          setState(() => _fajrMuezzinId = value ?? ''),
                      child: Column(
                        children: [
                          _buildRow(
                            context: context,
                            id: '',
                            title: l10n.muezzinFajrSameAsGeneral,
                            subtitle: null,
                            isFajrSection: true,
                          ),
                          for (final muezzin in MuezzinCatalog.all)
                            if (muezzin.id != MuezzinCatalog.defaultId)
                              _buildRow(
                                context: context,
                                id: muezzin.id,
                                title: muezzin.name(l10n.localeName),
                                subtitle: muezzin.origin(l10n.localeName),
                                isFajrSection: true,
                                fajrOptimized: muezzin.fajrOptimized,
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await widget.previewService.stop();
                  if (!context.mounted) return;
                  final cubit = context.read<NotificationSettingsCubit>();
                  await cubit.setMuezzin(_muezzinId, l10n: l10n);
                  await cubit.setFajrMuezzin(_fajrMuezzinId, l10n: l10n);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: widget.primary,
                ),
                child: Text(l10n.muezzinPickerSave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required BuildContext context,
    required String id,
    required String title,
    required String? subtitle,
    required bool isFajrSection,
    bool fajrOptimized = false,
  }) {
    final selected = isFajrSection ? _fajrMuezzinId == id : _muezzinId == id;
    final previewing = _previewingId == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Radio<String>(
        value: id,
        activeColor: widget.primary,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (fajrOptimized) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                context.l10n.muezzinFajrBadge,
                style: AppTypography.labelSmall.copyWith(
                  color: widget.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
      trailing: IconButton(
        icon: Icon(
          previewing ? Icons.stop_circle_rounded : Icons.play_circle_rounded,
          color: widget.primary,
        ),
        tooltip: previewing
            ? context.l10n.muezzinPreviewStop
            : context.l10n.muezzinPreviewPlay,
        onPressed: () => _togglePreview(id),
      ),
      onTap: () => setState(() {
        if (isFajrSection) {
          _fajrMuezzinId = id;
        } else {
          _muezzinId = id;
        }
      }),
    );
  }
}
