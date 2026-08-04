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
    SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
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

  Future<void> _toggleReview(bool value) async {
    final l10n = context.l10n;
    final previous = _reviewEnabled;
    setState(() {
      _reviewEnabled = value;
      _savingReview = true;
    });

    try {
      await _ensureNotificationPermissionIfEnabling(value);
      final saved = await getIt<SharedPreferences>().setBool(_reviewKey, value);
      if (!saved) {
        throw StateError('Failed to save daily review notification setting');
      }
      await getIt<NotificationScheduler>().refreshNotifications(l10n);
    } catch (_) {
      if (!mounted) return;
      setState(() => _reviewEnabled = previous);
      _showSettingsError(context, l10n.reviewReminderSaveError);
    } finally {
      if (mounted) {
        setState(() => _savingReview = false);
      }
    }
  }

  Future<void> _toggleStreak(bool value) async {
    final l10n = context.l10n;
    final previous = _streakEnabled;
    setState(() {
      _streakEnabled = value;
      _savingStreak = true;
    });

    try {
      await _ensureNotificationPermissionIfEnabling(value);
      final saved = await getIt<SharedPreferences>().setBool(_streakKey, value);
      if (!saved) {
        throw StateError('Failed to save streak notification setting');
      }
      await getIt<NotificationScheduler>().refreshNotifications(l10n);
    } catch (_) {
      if (!mounted) return;
      setState(() => _streakEnabled = previous);
      _showSettingsError(context, l10n.streakReminderSaveError);
    } finally {
      if (mounted) {
        setState(() => _savingStreak = false);
      }
    }
  }

  Future<void> _toggleMorningAzkar(bool value) async {
    final l10n = context.l10n;
    final previous = _morningAzkarEnabled;
    setState(() {
      _morningAzkarEnabled = value;
      _savingMorningAzkar = true;
    });

    try {
      await _ensureNotificationPermissionIfEnabling(value);
      final saved = await getIt<SharedPreferences>().setBool(
        _morningAzkarKey,
        value,
      );
      if (!saved) {
        throw StateError('Failed to save morning azkar notification setting');
      }
      await getIt<NotificationScheduler>().refreshNotifications(l10n);
    } catch (_) {
      if (!mounted) return;
      setState(() => _morningAzkarEnabled = previous);
      _showSettingsError(context, l10n.morningAzkarSaveError);
    } finally {
      if (mounted) {
        setState(() => _savingMorningAzkar = false);
      }
    }
  }

  Future<void> _toggleEveningAzkar(bool value) async {
    final l10n = context.l10n;
    final previous = _eveningAzkarEnabled;
    setState(() {
      _eveningAzkarEnabled = value;
      _savingEveningAzkar = true;
    });

    try {
      await _ensureNotificationPermissionIfEnabling(value);
      final saved = await getIt<SharedPreferences>().setBool(
        _eveningAzkarKey,
        value,
      );
      if (!saved) {
        throw StateError('Failed to save evening azkar notification setting');
      }
      await getIt<NotificationScheduler>().refreshNotifications(l10n);
    } catch (_) {
      if (!mounted) return;
      setState(() => _eveningAzkarEnabled = previous);
      _showSettingsError(context, l10n.eveningAzkarSaveError);
    } finally {
      if (mounted) {
        setState(() => _savingEveningAzkar = false);
      }
    }
  }

  Future<void> _toggleDailyDua(bool value) async {
    final l10n = context.l10n;
    final previous = _dailyDuaEnabled;
    setState(() {
      _dailyDuaEnabled = value;
      _savingDailyDua = true;
    });

    try {
      await _ensureNotificationPermissionIfEnabling(value);
      final saved = await getIt<SharedPreferences>().setBool(
        _dailyDuaKey,
        value,
      );
      if (!saved) {
        throw StateError('Failed to save daily dua notification setting');
      }
      await getIt<NotificationScheduler>().refreshNotifications(l10n);
    } catch (_) {
      if (!mounted) return;
      setState(() => _dailyDuaEnabled = previous);
      _showSettingsError(context, l10n.dailyDuaSaveError);
    } finally {
      if (mounted) {
        setState(() => _savingDailyDua = false);
      }
    }
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
    final effectiveOpacity = isEnabled ? 1.0 : 0.64;

    return InkWell(
      onTap: onTapEdit,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedOpacity(
        opacity: effectiveOpacity,
        duration: const Duration(milliseconds: 180),
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
                  color: primaryColor.withValues(alpha: 0.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 21),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          context.l10n.notificationEverydayAt(
                            _formatTime(time),
                          ),
                          style: AppTypography.labelSmall.copyWith(
                            color: subtextColor,
                          ),
                        ),
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: primaryColor.withValues(alpha: 0.72),
                        ),
                      ],
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
        _buildTimeEditorTile(
          title: context.l10n.dailyReviewReminder,
          time: _reviewTime,
          isEnabled: _reviewEnabled,
          isSaving: _savingReview,
          onToggle: _toggleReview,
          icon: Icons.notifications_active_rounded,
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
          icon: Icons.shield_rounded,
          primaryColor: primary,
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
          primaryColor: primary,
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
          primaryColor: primary,
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
          primaryColor: primary,
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
                    color: primary.withValues(alpha: 0.11),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.isArabic
                            ? 'اختبار إشعارات الأذكار، المراجعة، والسلسلة المخصصة'
                            : 'Test customized Azkar, Review, and Streak notifications',
                        style: AppTypography.labelSmall.copyWith(
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.isArabic
                      ? 'سيصلك إشعار فوري يحتوي على أزرار التفاعل المطابقة لمضمونه'
                      : 'You will receive an instant notification with actions matching its topic',
                  style: AppTypography.bodySmall.copyWith(color: subtextColor),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Color(0xFFF39C12),
                  ),
                  title: Text(
                    context.isArabic ? 'أذكار الصباح ☀️' : 'Morning Azkar ☀️',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'الأزرار: [ ☀️ قراءة أذكار الصباح ] [ 📖 الورد اليومي ]'
                        : 'Actions: [ ☀️ Read Morning Azkar ] [ 📖 Daily Portion ]',
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? 'أذكار الصباح ☀️'
                              : 'Morning Azkar ☀️',
                          body: context.isArabic
                              ? 'ابدأ يومك بذكر الله وطمأنينة القلب ✨'
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
                        ? 'المراجعة اليومية 📖'
                        : 'Daily Review 📖',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'الأزرار: [ ⚡ ابدأ المراجعة ] [ 📖 الورد اليومي ]'
                        : 'Actions: [ ⚡ Start Review ] [ 📖 Daily Portion ]',
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? 'وقت المراجعة اليومية 📖'
                              : 'Daily Review Time 📖',
                          body: context.isArabic
                              ? 'لديك 5 آيات مستحقة للمراجعة اليوم ⚡'
                              : 'You have 5 ayahs due for review today ⚡',
                          type: 'review',
                        );
                    _showTestSuccessSnackBar();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFE67E22),
                  ),
                  title: Text(
                    context.isArabic
                        ? 'حماية السلسلة 🔥'
                        : 'Streak Protection 🔥',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'الأزرار: [ 🔥 احمي السلسلة الآن ] [ 📖 قراءة الورد ]'
                        : 'Actions: [ 🔥 Protect Streak Now ] [ 📖 Read Portion ]',
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? '⚠️ لا تُضيِّع 7 أيام متتالية!'
                              : "⚠️ Don't lose 7 days streak!",
                          body: context.isArabic
                              ? 'لم تراجع حفظك اليوم بعد — احمي سلسلتك الآن 🔥'
                              : "You haven't reviewed today — protect your streak now 🔥",
                          type: 'streak',
                        );
                    _showTestSuccessSnackBar();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.volunteer_activism_rounded,
                    color: Color(0xFF2980B9),
                  ),
                  title: Text(
                    context.isArabic ? 'دعاء اليوم 🤲' : 'Daily Dua 🤲',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    context.isArabic
                        ? 'الأزرار: [ 🤲 قراءة أدعية اليوم ] [ ✨ الأذكار ]'
                        : "Actions: [ 🤲 Read Today's Duas ] [ ✨ Azkar ]",
                    style: TextStyle(color: subtextColor, fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await getIt<TaliaNotificationService>()
                        .showImmediateTestNotification(
                          title: context.isArabic
                              ? 'دعاء اليوم 🤲'
                              : 'Daily Dua 🤲',
                          body:
                              'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ.',
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
              ? 'تم إرسال الإشعار التفاعلي التجريبي بنجاح ✨'
              : 'Interactive test notification sent successfully ✨',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
