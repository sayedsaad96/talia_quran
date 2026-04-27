import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/notification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../data/profile_cubit.dart';
import '../../data/user_profile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.pagePadding,
              120, // Prevent cutoff by bottom nav
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SettingsSection(
                  title: context.l10n.profile,
                  children: [_ProfileSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.l10n.theme,
                  children: [_ThemeSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.l10n.language,
                  children: [_LocaleSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.isArabic ? 'دقة التسميع' : 'Recitation Accuracy',
                  children: [_AccuracySettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.isArabic ? 'الإشعارات' : 'Notifications',
                  children: [_NotificationSettingTile(isDark: isDark)],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSection(
                  title: context.isArabic ? 'حول التطبيق' : 'About',
                  children: [_AboutTile(isDark: isDark)],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          size: 20,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      title: Text(
        context.l10n.settings,
        style: AppTypography.headlineSmall.copyWith(
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
        ),
      ),
      centerTitle: true,
    );
  }
}

// ─── Section Container ────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04);
  }
}

// ─── Theme Toggle ─────────────────────────────────────────────────────────────

class _ThemeSettingTile extends StatelessWidget {
  const _ThemeSettingTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final primary = isDark ? AppColors.primaryLight : AppColors.primary;

        return Column(
          children: [
            _ThemeOption(
              label: context.l10n.lightMode,
              icon: Icons.light_mode_rounded,
              isSelected: themeMode == ThemeMode.light,
              color: const Color(0xFFFF8C42),
              isDark: isDark,
              onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.light),
            ),
            Divider(
              height: 0.5,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              indent: 56,
            ),
            _ThemeOption(
              label: context.l10n.darkMode,
              icon: Icons.dark_mode_rounded,
              isSelected: themeMode == ThemeMode.dark,
              color: const Color(0xFF2D5A8E),
              isDark: isDark,
              onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.dark),
            ),
            Divider(
              height: 0.5,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              indent: 56,
            ),
            _ThemeOption(
              label: context.isArabic ? 'حسب النظام' : 'System Default',
              icon: Icons.brightness_auto_rounded,
              isSelected: themeMode == ThemeMode.system,
              color: primary,
              isDark: isDark,
              onTap: () =>
                  context.read<ThemeCubit>().setTheme(ThemeMode.system),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(color: textColor),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Locale Toggle ────────────────────────────────────────────────────────────

class _LocaleSettingTile extends StatelessWidget {
  const _LocaleSettingTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isAr = locale.languageCode == 'ar';
        final primary = isDark ? AppColors.primaryLight : AppColors.primary;

        return Column(
          children: [
            _LocaleOption(
              label: 'العربية',
              sublabel: 'Arabic',
              flag: '🇸🇦',
              isSelected: isAr,
              color: primary,
              isDark: isDark,
              onTap: () =>
                  context.read<LocaleCubit>().setLocale(const Locale('ar')),
            ),
            Divider(
              height: 0.5,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              indent: 56,
            ),
            _LocaleOption(
              label: 'English',
              sublabel: 'الإنجليزية',
              flag: '🇬🇧',
              isSelected: !isAr,
              color: primary,
              isDark: isDark,
              onTap: () =>
                  context.read<LocaleCubit>().setLocale(const Locale('en')),
            ),
          ],
        );
      },
    );
  }
}

class _LocaleOption extends StatelessWidget {
  const _LocaleOption({
    required this.label,
    required this.sublabel,
    required this.flag,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final String flag;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextHint
        : AppColors.lightTextHint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(color: textColor),
                  ),
                  Text(
                    sublabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 12,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── About Tile ───────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Center(
              child: Text(
                'ت',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تالية — Talia',
                  style: AppTypography.titleLarge.copyWith(color: textColor),
                ),
                Text(
                  'Version 1.0.0',
                  style: AppTypography.bodySmall.copyWith(color: subtextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  context.isArabic
                      ? 'تطبيق متميز لحفظ ومراجعة القرآن الكريم'
                      : 'A premium Quran memorization app',
                  style: AppTypography.labelSmall.copyWith(color: subtextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Section ─────────────────────────────────────────────────────────

class _ProfileSettingTile extends StatelessWidget {
  const _ProfileSettingTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        final profile = (state is ProfileLoaded) ? state.profile : const UserProfile();
        
        return InkWell(
          onTap: () => _showEditProfileDialog(context, profile, isDark),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.hasName ? profile.displayName : context.l10n.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontWeight: profile.hasName ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (profile.age != null)
                        Text(
                          '${context.l10n.age}: ${profile.age}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        )
                      else 
                        Text(
                          context.l10n.editProfile,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context, UserProfile profile, bool isDark) {
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(text: profile.age?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          title: Text(
            context.l10n.editProfile,
            style: AppTypography.titleLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: InputDecoration(
                  labelText: context.l10n.name,
                  hintText: context.l10n.enterName,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: InputDecoration(
                  labelText: context.l10n.age,
                  hintText: context.l10n.enterAge,
                ),
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text.trim());
                context.read<ProfileCubit>().updateProfile(name: name, age: age);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.profileUpdated)),
                );
              },
              child: Text(context.l10n.save),
            ),
          ],
        );
      },
    );
  }
}

// ─── Accuracy Setting ────────────────────────────────────────────────────────

class _AccuracySettingTile extends StatefulWidget {
  const _AccuracySettingTile({required this.isDark});
  final bool isDark;

  @override
  State<_AccuracySettingTile> createState() => _AccuracySettingTileState();
}

class _AccuracySettingTileState extends State<_AccuracySettingTile> {
  static const _key = 'similarity_threshold';
  static const _levels = [0.70, 0.85, 0.92];
  int _selected = 1; // default = medium (0.85)

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    final saved = prefs.getDouble(_key) ?? 0.85;
    if (saved <= 0.70) {
      _selected = 0;
    } else if (saved >= 0.92) {
      _selected = 2;
    } else {
      _selected = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;

    final labels = context.isArabic
        ? ['سهل (٧٠٪)', 'متوسط (٨٥٪)', 'صعب (٩٢٪)']
        : ['Easy (70%)', 'Medium (85%)', 'Hard (92%)'];

    return ListTile(
      leading: Icon(Icons.mic_rounded, color: primary),
      title: Text(
        context.isArabic ? 'مستوى الدقة' : 'Accuracy Level',
        style: AppTypography.bodyMedium.copyWith(color: textColor),
      ),
      trailing: SegmentedButton<int>(
        segments: [
          for (int i = 0; i < 3; i++)
            ButtonSegment(value: i, label: Text(labels[i], style: const TextStyle(fontSize: 11))),
        ],
        selected: {_selected},
        onSelectionChanged: (val) {
          setState(() => _selected = val.first);
          getIt<SharedPreferences>().setDouble(_key, _levels[_selected]);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

// ─── Notification Settings ───────────────────────────────────────────────────

class _NotificationSettingTile extends StatefulWidget {
  const _NotificationSettingTile({required this.isDark});
  final bool isDark;

  @override
  State<_NotificationSettingTile> createState() =>
      _NotificationSettingTileState();
}

class _NotificationSettingTileState extends State<_NotificationSettingTile> {
  static const _reviewKey = 'notifications_daily_review';
  static const _streakKey = 'notifications_streak_alert';

  bool _reviewEnabled = true;
  bool _streakEnabled = true;

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    _reviewEnabled = prefs.getBool(_reviewKey) ?? true;
    _streakEnabled = prefs.getBool(_streakKey) ?? true;
  }

  Future<void> _toggleReview(bool value) async {
    setState(() => _reviewEnabled = value);
    await getIt<SharedPreferences>().setBool(_reviewKey, value);
    if (value) {
      await TaliaNotificationService.instance.scheduleDailyReviewReminder();
    } else {
      // Cancel only the review notification (ID 1001)
      await TaliaNotificationService.instance.cancelAll();
      // Re-schedule streak if still enabled
      if (_streakEnabled) {
        await TaliaNotificationService.instance
            .scheduleStreakProtectionAlert(currentStreak: 1);
      }
    }
  }

  Future<void> _toggleStreak(bool value) async {
    setState(() => _streakEnabled = value);
    await getIt<SharedPreferences>().setBool(_streakKey, value);
    if (value) {
      await TaliaNotificationService.instance
          .scheduleStreakProtectionAlert(currentStreak: 1);
    } else {
      await TaliaNotificationService.instance.cancelStreakAlert();
    }
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
        SwitchListTile(
          secondary: Icon(Icons.notifications_active_rounded, color: primary),
          title: Text(
            context.isArabic ? 'تذكير المراجعة اليومية' : 'Daily Review Reminder',
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.isArabic ? 'كل يوم الساعة ٨:٠٠ مساءً' : 'Every day at 8:00 PM',
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          value: _reviewEnabled,
          onChanged: _toggleReview,
          activeThumbColor: primary,
        ),
        Divider(
          height: 0.5,
          color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
          indent: 56,
        ),
        SwitchListTile(
          secondary: Icon(Icons.shield_rounded, color: primary),
          title: Text(
            context.isArabic ? 'حماية السلسلة' : 'Streak Protection',
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.isArabic
                ? 'تنبيه الساعة ١٠:٠٠ مساءً إذا لم تراجع'
                : 'Alert at 10:00 PM if no review',
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          value: _streakEnabled,
          onChanged: _toggleStreak,
          activeThumbColor: primary,
        ),
      ],
    );
  }
}
