import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'settings_section.dart';

void _showSettingsError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    ),
  );
}

class NotificationSettingTile extends StatefulWidget {
  const NotificationSettingTile({super.key, required this.isDark});
  final bool isDark;

  @override
  State<NotificationSettingTile> createState() =>
      _NotificationSettingTileState();
}

class _NotificationSettingTileState extends State<NotificationSettingTile> {
  static const _reviewKey = TaliaNotificationService.dailyReviewPreferenceKey;
  static const _streakKey = TaliaNotificationService.streakAlertPreferenceKey;
  static const _morningAzkarKey =
      TaliaNotificationService.morningAzkarPreferenceKey;
  static const _eveningAzkarKey =
      TaliaNotificationService.eveningAzkarPreferenceKey;
  static const _dailyDuaKey = TaliaNotificationService.dailyDuaPreferenceKey;

  bool _reviewEnabled = true;
  bool _streakEnabled = true;
  bool _morningAzkarEnabled = true;
  bool _eveningAzkarEnabled = true;
  bool _dailyDuaEnabled = true;
  bool _savingReview = false;
  bool _savingStreak = false;
  bool _savingMorningAzkar = false;
  bool _savingEveningAzkar = false;
  bool _savingDailyDua = false;

  TimeOfDay _reviewTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _streakTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _morningAzkarTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _eveningAzkarTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _dailyDuaTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    _reviewEnabled = prefs.getBool(_reviewKey) ?? true;
    _streakEnabled = prefs.getBool(_streakKey) ?? true;
    _morningAzkarEnabled = prefs.getBool(_morningAzkarKey) ?? true;
    _eveningAzkarEnabled = prefs.getBool(_eveningAzkarKey) ?? true;
    _dailyDuaEnabled = prefs.getBool(_dailyDuaKey) ?? true;

    _reviewTime = TimeOfDay(
      hour: prefs.getInt('${_reviewKey}_hour') ?? 20,
      minute: prefs.getInt('${_reviewKey}_minute') ?? 0,
    );
    _streakTime = TimeOfDay(
      hour: prefs.getInt('${_streakKey}_hour') ?? 22,
      minute: prefs.getInt('${_streakKey}_minute') ?? 0,
    );
    _morningAzkarTime = TimeOfDay(
      hour: prefs.getInt('${_morningAzkarKey}_hour') ?? 6,
      minute: prefs.getInt('${_morningAzkarKey}_minute') ?? 0,
    );
    _eveningAzkarTime = TimeOfDay(
      hour: prefs.getInt('${_eveningAzkarKey}_hour') ?? 18,
      minute: prefs.getInt('${_eveningAzkarKey}_minute') ?? 0,
    );
    _dailyDuaTime = TimeOfDay(
      hour: prefs.getInt('${_dailyDuaKey}_hour') ?? 9,
      minute: prefs.getInt('${_dailyDuaKey}_minute') ?? 0,
    );
  }

  int get _activeRemindersCount {
    int count = 0;
    if (_reviewEnabled) count++;
    if (_streakEnabled) count++;
    if (_morningAzkarEnabled) count++;
    if (_eveningAzkarEnabled) count++;
    if (_dailyDuaEnabled) count++;
    return count;
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
    bool isEnabled,
    void Function(TimeOfDay) onTimeSelected,
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
      setState(() => onTimeSelected(newTime));
      final prefs = getIt<SharedPreferences>();
      await prefs.setInt('${key}_hour', newTime.hour);
      await prefs.setInt('${key}_minute', newTime.minute);
      if (isEnabled) {
        await getIt<NotificationScheduler>().refreshNotifications(l10n);
      }
    }
  }

  Future<void> _ensureNotificationPermissionIfEnabling(bool enabled) async {
    if (enabled) {
      await getIt<TaliaNotificationService>().requestPermissions();
    }
  }

  Future<void> _toggleSetting({
    required String key,
    required bool value,
    required bool previous,
    required void Function(bool) onSavingStateChanged,
    required void Function(bool) onValueStateChanged,
    required String errorMessage,
  }) async {
    final l10n = context.l10n;
    if (!mounted) return;
    setState(() {
      onValueStateChanged(value);
      onSavingStateChanged(true);
    });

    try {
      final saved = await getIt<SharedPreferences>().setBool(key, value);
      if (!saved) {
        throw StateError('Failed to save setting $key');
      }
      try {
        await _ensureNotificationPermissionIfEnabling(value);
        await getIt<NotificationScheduler>().refreshNotifications(l10n);
      } catch (e) {
        debugPrint('Error scheduling notification for $key: $e');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => onValueStateChanged(previous));
      _showSettingsError(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() => onSavingStateChanged(false));
      }
    }
  }

  Future<void> _toggleReview(bool value) async {
    await _toggleSetting(
      key: _reviewKey,
      value: value,
      previous: _reviewEnabled,
      onSavingStateChanged: (s) => _savingReview = s,
      onValueStateChanged: (v) => _reviewEnabled = v,
      errorMessage: context.l10n.reviewReminderSaveError,
    );
  }

  Future<void> _toggleStreak(bool value) async {
    await _toggleSetting(
      key: _streakKey,
      value: value,
      previous: _streakEnabled,
      onSavingStateChanged: (s) => _savingStreak = s,
      onValueStateChanged: (v) => _streakEnabled = v,
      errorMessage: context.l10n.streakReminderSaveError,
    );
  }

  Future<void> _toggleMorningAzkar(bool value) async {
    await _toggleSetting(
      key: _morningAzkarKey,
      value: value,
      previous: _morningAzkarEnabled,
      onSavingStateChanged: (s) => _savingMorningAzkar = s,
      onValueStateChanged: (v) => _morningAzkarEnabled = v,
      errorMessage: context.l10n.morningAzkarSaveError,
    );
  }

  Future<void> _toggleEveningAzkar(bool value) async {
    await _toggleSetting(
      key: _eveningAzkarKey,
      value: value,
      previous: _eveningAzkarEnabled,
      onSavingStateChanged: (s) => _savingEveningAzkar = s,
      onValueStateChanged: (v) => _eveningAzkarEnabled = v,
      errorMessage: context.l10n.eveningAzkarSaveError,
    );
  }

  Future<void> _toggleDailyDua(bool value) async {
    await _toggleSetting(
      key: _dailyDuaKey,
      value: value,
      previous: _dailyDuaEnabled,
      onSavingStateChanged: (s) => _savingDailyDua = s,
      onValueStateChanged: (v) => _dailyDuaEnabled = v,
      errorMessage: context.l10n.dailyDuaSaveError,
    );
  }

  Widget _buildTimeEditorTile({
    required String title,
    required TimeOfDay time,
    required bool isEnabled,
    required bool isSaving,
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
                  GestureDetector(
                    onTap: isEnabled ? onTapEdit : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? primaryColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: isEnabled
                              ? primaryColor.withValues(alpha: 0.25)
                              : subtextColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isEnabled ? primaryColor : subtextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.notificationEverydayAt(
                              _formatTime(time),
                            ),
                            style: AppTypography.labelSmall.copyWith(
                              color: isEnabled ? primaryColor : subtextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isEnabled) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: primaryColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(
              value: isEnabled,
              onChanged: isSaving ? null : onToggle,
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

    return Column(
      children: [
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
                    color: _activeRemindersCount > 0
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_activeRemindersCount > 0
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.isArabic
                        ? 'حالة التنبيهات: $_activeRemindersCount من 5 تذكيرات مفعلة'
                        : 'Notification status: $_activeRemindersCount of 5 reminders active',
                    style: AppTypography.labelMedium.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildTimeEditorTile(
          title: context.l10n.dailyReviewReminder,
          time: _reviewTime,
          isEnabled: _reviewEnabled,
          isSaving: _savingReview,
          onToggle: _toggleReview,
          icon: Icons.auto_stories_rounded,
          primaryColor: primary,
          textColor: textColor,
          subtextColor: subtextColor,
          onTapEdit: () => _pickTime(
            _reviewKey,
            _reviewTime,
            _reviewEnabled,
            (t) => setState(() => _reviewTime = t),
          ),
        ),
        SettingsDivider(isDark: widget.isDark),
        _buildTimeEditorTile(
          title: context.l10n.streakProtection,
          time: _streakTime,
          isEnabled: _streakEnabled,
          isSaving: _savingStreak,
          onToggle: _toggleStreak,
          icon: Icons.local_fire_department_rounded,
          primaryColor: AppColors.amber,
          textColor: textColor,
          subtextColor: subtextColor,
          onTapEdit: () => _pickTime(
            _streakKey,
            _streakTime,
            _streakEnabled,
            (t) => setState(() => _streakTime = t),
          ),
        ),
        SettingsDivider(isDark: widget.isDark),
        _buildTimeEditorTile(
          title: context.l10n.morningAzkarReminder,
          time: _morningAzkarTime,
          isEnabled: _morningAzkarEnabled,
          isSaving: _savingMorningAzkar,
          onToggle: _toggleMorningAzkar,
          icon: Icons.wb_sunny_rounded,
          primaryColor: AppColors.gold,
          textColor: textColor,
          subtextColor: subtextColor,
          onTapEdit: () => _pickTime(
            _morningAzkarKey,
            _morningAzkarTime,
            _morningAzkarEnabled,
            (t) => setState(() => _morningAzkarTime = t),
          ),
        ),
        SettingsDivider(isDark: widget.isDark),
        _buildTimeEditorTile(
          title: context.l10n.eveningAzkarReminder,
          time: _eveningAzkarTime,
          isEnabled: _eveningAzkarEnabled,
          isSaving: _savingEveningAzkar,
          onToggle: _toggleEveningAzkar,
          icon: Icons.nightlight_round,
          primaryColor: const Color(0xFF8E44AD),
          textColor: textColor,
          subtextColor: subtextColor,
          onTapEdit: () => _pickTime(
            _eveningAzkarKey,
            _eveningAzkarTime,
            _eveningAzkarEnabled,
            (t) => setState(() => _eveningAzkarTime = t),
          ),
        ),
        SettingsDivider(isDark: widget.isDark),
        _buildTimeEditorTile(
          title: context.l10n.dailyDuaReminder,
          time: _dailyDuaTime,
          isEnabled: _dailyDuaEnabled,
          isSaving: _savingDailyDua,
          onToggle: _toggleDailyDua,
          icon: Icons.volunteer_activism_rounded,
          primaryColor: AppColors.info,
          textColor: textColor,
          subtextColor: subtextColor,
          onTapEdit: () => _pickTime(
            _dailyDuaKey,
            _dailyDuaTime,
            _dailyDuaEnabled,
            (t) => setState(() => _dailyDuaTime = t),
          ),
        ),
        SettingsDivider(isDark: widget.isDark),
        InkWell(
          onTap: () => _showTestNotificationPicker(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.touch_app_rounded, color: primary, size: 21),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.isArabic
                            ? 'تجربة الإشعارات التفاعلية'
                            : 'Test Interactive Notification',
                        style: AppTypography.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.isArabic
                            ? 'اختبار إشعارات الأذكار والمراجعة باللهجة المشجعة'
                            : 'Test customized Azkar and Review notifications',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTestNotificationPicker(BuildContext context) async {
    final surface = widget.isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.isArabic
                      ? 'اختر نوع الإشعار التفاعلي للتجربة'
                      : 'Select notification type to test',
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.isArabic
                      ? 'سيصلك إشعار تحفيزي فوري يحتوي على أزرار التفاعل المباشرة'
                      : 'You will receive an encouraging notification with action buttons',
                  style: AppTypography.bodySmall.copyWith(color: subtextColor),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.wb_sunny_rounded,
                    color: AppColors.gold,
                  ),
                  title: Text(
                    context.isArabic ? 'صبحك الله بالخير ☀️' : 'Morning Azkar ☀️',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'يلا ابدأ يومك بذكر الله وطمئن قلبك.. أذكار الصباح في انتظارك'
                        : 'Start your day with remembrance of Allah ✨',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? 'صبحك الله بالخير ☀️'
                              : 'Morning Azkar ☀️',
                          body: context.isArabic
                              ? 'يلا ابدأ يومك بذكر الله وطمئن قلبك.. أذكار الصباح في انتظارك'
                              : 'Start your day with remembrance of Allah ✨',
                          type: 'azkar',
                        );
                    _showTestSuccessSnackBar();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    context.isArabic
                        ? 'جاهز نراجع سوا؟ 📖'
                        : 'Daily Review 📖',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'عندك 5 آيات مستنية مراجعتك النهاردة.. يلا خطوة بخطوة! ✨'
                        : 'You have 5 ayahs due for review today ⚡',
                    style: AppTypography.bodySmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? 'جاهز نراجع سوا؟ 📖'
                              : 'Daily Review Time 📖',
                          body: context.isArabic
                              ? 'عندك 5 آيات مستنية مراجعتك النهاردة.. يلا خطوة بخطوة! ✨'
                              : 'You have 5 ayahs due for review today ⚡',
                          type: 'review',
                        );
                    _showTestSuccessSnackBar();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.amber,
                  ),
                  title: Text(
                    context.isArabic
                        ? '⚠️ متضيعش إنجاز 7 أيام!'
                        : 'Streak Protection 🔥',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'فاضل تكة صغيرة وتكمل وردك النهاردة.. متكسلش، تقدر تعملها! 🔥'
                        : "You haven't reviewed today — protect your streak now 🔥",
                    style: AppTypography.bodySmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? '⚠️ متضيعش إنجاز 7 أيام!'
                              : "⚠️ Don't lose 7 days streak!",
                          body: context.isArabic
                              ? 'فاضل تكة صغيرة وتكمل وردك النهاردة.. متكسلش، تقدر تعملها! 🔥'
                              : "You haven't reviewed today — protect your streak now 🔥",
                          type: 'streak',
                        );
                    _showTestSuccessSnackBar();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.info,
                  ),
                  title: Text(
                    context.isArabic ? 'دعوة من القلب 🤲' : 'Daily Dua 🤲',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'هنا يظهر نص تذكير الدعاء اليومي من المصحف المعتمد'
                        : "Today's dua reminder text from the approved corpus appears here",
                    style: AppTypography.bodySmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? 'دعوة من القلب 🤲'
                              : 'Daily Dua 🤲',
                          body: context.isArabic
                              ? 'هذا مثال لشكل تذكير الدعاء اليومي'
                              : 'This is a preview of the daily dua reminder',
                          type: 'dua',
                        );
                    _showTestSuccessSnackBar();
                  },
                ),
              ],
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
}
