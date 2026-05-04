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
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/profile_cubit.dart';
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
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ─── Account (Google Sign-In) ───────────────────────
                    _SettingsSection(
                      title: context.isArabic ? 'الحساب' : 'Account',
                      children: [_AccountSection(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                      title: context.l10n.recitationAccuracy,
                      children: [_AccuracySettingTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.l10n.notifications,
                      children: [_NotificationSettingTile(isDark: isDark)],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsSection(
                      title: context.l10n.about,
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
              label: context.l10n.systemDefault,
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
                color: color.withValues(alpha: 0.1),
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
        final profile = (state is ProfileLoaded)
            ? state.profile
            : const UserProfile();

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
                    color: (isDark ? AppColors.primaryLight : AppColors.primary)
                        .withValues(alpha: 0.1),
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
                        profile.hasName
                            ? profile.displayName
                            : context.l10n.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: profile.hasName
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (profile.age != null)
                        Text(
                          '${context.l10n.age}: ${profile.age}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        )
                      else
                        Text(
                          context.l10n.editProfile,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
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

  void _showEditProfileDialog(
    BuildContext context,
    UserProfile profile,
    bool isDark,
  ) {
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(
      text: profile.age?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Text(
            context.l10n.editProfile,
            style: AppTypography.titleLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.name,
                    hintText: context.l10n.enterName,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
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
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final age = int.tryParse(ageController.text.trim());
                context.read<ProfileCubit>().updateProfile(
                  name: name,
                  age: age,
                );
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
      trailing: DropdownButton<int>(
        value: _selected,
        items: [
          for (int i = 0; i < 3; i++)
            DropdownMenuItem(
              value: i,
              child: Text(labels[i], style: const TextStyle(fontSize: 12)),
            ),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _selected = val);
            getIt<SharedPreferences>().setDouble(_key, _levels[_selected]);
          }
        },
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down_rounded, color: primary),
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
      await TaliaNotificationService.instance.cancelDailyReviewReminder();
      // Re-schedule streak if still enabled
      if (_streakEnabled) {
        await TaliaNotificationService.instance.scheduleStreakProtectionAlert(
          currentStreak: 1,
        );
      }
    }
  }

  Future<void> _toggleStreak(bool value) async {
    setState(() => _streakEnabled = value);
    await getIt<SharedPreferences>().setBool(_streakKey, value);
    if (value) {
      await TaliaNotificationService.instance.scheduleStreakProtectionAlert(
        currentStreak: 1,
      );
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
            context.isArabic
                ? 'تذكير المراجعة اليومية'
                : 'Daily Review Reminder',
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.isArabic
                ? 'كل يوم الساعة ٨:٠٠ مساءً'
                : 'Every day at 8:00 PM',
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

// ─── Account Section (Email & Password Auth) ─────────────────────────────────

class _AccountSection extends StatefulWidget {
  const _AccountSection({required this.isDark});
  final bool isDark;

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    if (_isSignUp) {
      cubit.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
    } else {
      cubit.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor =
        widget.isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor =
        widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final fieldFill = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        } else if (state is AuthAuthenticated) {
          // Update local profile automatically with the user's display name
          context.read<ProfileCubit>().updateProfile(name: state.user.displayName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.isArabic
                    ? (_isSignUp ? 'تم إنشاء الحساب بنجاح ✓' : 'تم تسجيل الدخول بنجاح ✓')
                    : (_isSignUp ? 'Account created ✓' : 'Signed in successfully ✓'),
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // ─── Signed-in view ────────────────────────────────────────
        if (state is AuthAuthenticated) {
          final user = state.user;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primary.withValues(alpha: 0.15),
                      child: Icon(Icons.person_rounded, color: primary, size: 26),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: AppTypography.bodyMedium.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            user.email,
                            style: AppTypography.labelSmall
                                .copyWith(color: subtextColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.cloud_done_rounded,
                                  size: 12, color: Colors.green.shade500),
                              const SizedBox(width: 4),
                              Text(
                                context.isArabic
                                    ? 'تقدمك محفوظ على السحابة'
                                    : 'Progress backed up',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.green.shade500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 0.5,
                color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
                indent: 16,
                endIndent: 16,
              ),
              InkWell(
                onTap: () => _confirmSignOut(context),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.radiusLg)),
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
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(Icons.logout_rounded,
                            color: Colors.red, size: 18),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        context.isArabic ? 'تسجيل الخروج' : 'Sign Out',
                        style:
                            AppTypography.bodyMedium.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // ─── Unauthenticated view (Email/Password form) ───────────
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.isArabic
                            ? 'سجّل دخولك لحفظ تقدمك على جميع أجهزتك وعدم فقدانه عند مسح التطبيق.'
                            : 'Sign in to back up your progress and prevent data loss.',
                        style: AppTypography.bodySmall.copyWith(
                          color: subtextColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Sign In / Sign Up toggle
                Row(
                  children: [
                    _TabChip(
                      label: context.isArabic ? 'تسجيل دخول' : 'Sign In',
                      isSelected: !_isSignUp,
                      primary: primary,
                      textColor: textColor,
                      isDark: widget.isDark,
                      onTap: () => setState(() => _isSignUp = false),
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: context.isArabic ? 'حساب جديد' : 'Sign Up',
                      isSelected: _isSignUp,
                      primary: primary,
                      textColor: textColor,
                      isDark: widget.isDark,
                      onTap: () => setState(() => _isSignUp = true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Display Name (sign up only)
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    style: AppTypography.bodyMedium.copyWith(color: textColor),
                    decoration: _inputDecoration(
                      label: context.isArabic ? 'الاسم' : 'Name',
                      icon: Icons.person_outline_rounded,
                      primary: primary,
                      textColor: textColor,
                      fillColor: fieldFill,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.isArabic ? 'أدخل اسمك' : 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyMedium.copyWith(color: textColor),
                  decoration: _inputDecoration(
                    label: context.isArabic ? 'البريد الإلكتروني' : 'Email',
                    icon: Icons.email_outlined,
                    primary: primary,
                    textColor: textColor,
                    fillColor: fieldFill,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return context.isArabic ? 'أدخل بريدك الإلكتروني' : 'Enter your email';
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return context.isArabic ? 'بريد إلكتروني غير صحيح' : 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTypography.bodyMedium.copyWith(color: textColor),
                  decoration: _inputDecoration(
                    label: context.isArabic ? 'كلمة المرور' : 'Password',
                    icon: Icons.lock_outline_rounded,
                    primary: primary,
                    textColor: textColor,
                    fillColor: fieldFill,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: subtextColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return context.isArabic ? 'أدخل كلمة المرور' : 'Enter password';
                    }
                    if (_isSignUp && v.length < 6) {
                      return context.isArabic
                          ? '6 أحرف على الأقل'
                          : 'At least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Submit button
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    _isSignUp
                        ? (context.isArabic ? 'إنشاء حساب' : 'Create Account')
                        : (context.isArabic ? 'تسجيل الدخول' : 'Sign In'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color primary,
    required Color textColor,
    required Color fillColor,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.labelMedium.copyWith(color: textColor.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: primary, size: 20),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    final isDark = context.isDark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text(
          context.isArabic ? 'تسجيل الخروج' : 'Sign Out',
          style: AppTypography.titleLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        content: Text(
          context.isArabic
              ? 'هل تريد تسجيل الخروج؟ تقدمك المحفوظ على السحابة لن يُحذف.'
              : 'Sign out? Your cloud backup will remain safe.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(context.isArabic ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthCubit>().signOut();
            },
            child: Text(context.isArabic ? 'خروج' : 'Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Chip Widget ──────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.primary,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color primary;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? primary : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? primary : textColor.withValues(alpha: 0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
