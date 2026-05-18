part of 'settings_page.dart';

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

class _ParentDashboardTile extends StatelessWidget {
  const _ParentDashboardTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.push('/memorization-plus/parent-dashboard?surahId=1'),
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
                color: const Color(0xFF2D8E4C).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                color: Color(0xFF2D8E4C),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لوحة ولي الأمر',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'تابع حفظ الطفل والمكافآت والربط عن بعد',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ParentModeToggle extends StatelessWidget {
  const _ParentModeToggle({
    required this.isDark,
    required this.isParentMode,
    required this.onChanged,
  });

  final bool isDark;
  final bool isParentMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أنا ولي أمر',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'فعّل لمتابعة حفظ طفلك والربط عن بعد',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isParentMode,
            activeThumbColor: isDark
                ? AppColors.primaryLight
                : AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ResetMemorizationPathTile extends StatelessWidget {
  const _ResetMemorizationPathTile({
    required this.isDark,
    required this.onReset,
  });

  final bool isDark;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('إعادة ضبط مسار الحفظ؟', style: TextStyle(fontFamily: 'Amiri')),
            content: const Text(
              'سيؤدي هذا إلى إلغاء المسار المختار وحالة ربط ولي الأمر، ولكنه سيحتفظ بإعدادات الحفظ الذكي الخاصة بك.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأكيد إعادة الضبط'),
              ),
            ],
          ),
        );
        if (confirmed == true) await onReset();
      },
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
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restart_alt_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إعادة ضبط المسار',
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'اختر مسار الكبار أو الأطفال مرة أخرى بدون فقدان إعدادات الحفظ الذكي.',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
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

class _TutorialGuideTile extends StatelessWidget {
  const _TutorialGuideTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => context.push('/tutorial-guide'),
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
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book_rounded, color: primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دليل استخدام تالية',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'تعرف على كل مزايا التطبيق وطريقة استخدامها',
                    style: AppTypography.labelSmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: subtextColor,
            ),
          ],
        ),
      ),
    );
  }
}

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
    // Controllers are managed inside _EditProfileDialog (a StatefulWidget).
    // This ensures dispose() is called only after the exit animation completes,
    // preventing the "TextEditingController used after being disposed" error
    // that occurred when .whenComplete() disposed them mid-animation.
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _EditProfileDialog(profile: profile, isDark: isDark),
    );
  }
}

// ─── Edit Profile Dialog ──────────────────────────────────────────────────────
// Manages its own TextEditingControllers as State fields so they are disposed
// by Flutter only after the dialog's exit animation is complete.

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.isDark});

  final UserProfile profile;
  final bool isDark;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

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
              controller: _nameController,
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
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.xs,
                left: 4,
                right: 4,
              ),
              child: Text(
                context.isArabic
                    ? '💡 يفضل إدخال الاسم باللغة العربية ليظهر بشكل أجمل في الشهادات'
                    : '💡 Prefer entering your name in Arabic for better certificate appearance',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _ageController,
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
          onPressed: () => Navigator.of(context).pop(),
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
          onPressed: () async {
            final name = _nameController.text.trim();
            final ageText = _ageController.text.trim();
            final age = ageText.isEmpty ? null : int.tryParse(ageText);

            if (ageText.isNotEmpty && (age == null || age < 1 || age > 120)) {
              _showSettingsError(context, context.l10n.invalidAge);
              return;
            }

            final saved = await context.read<ProfileCubit>().updateProfile(
              name: name,
              age: age,
            );

            // Guard: context.mounted is required by the linter after an async gap.
            if (!context.mounted) return;

            if (!saved) {
              _showSettingsError(
                context,
                context.isArabic
                    ? 'تعذر حفظ الملف الشخصي'
                    : 'Could not save profile',
              );
              return;
            }

            Navigator.of(context).pop();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.profileUpdated)),
            );
          },
          child: Text(context.l10n.save),
        ),
      ],
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

    final labels = [
      context.l10n.difficultyEasy,
      context.l10n.difficultyMedium,
      context.l10n.difficultyHard,
    ];

    return ListTile(
      leading: Icon(Icons.mic_rounded, color: primary),
      title: Text(
        context.l10n.accuracyLevel,
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
        onChanged: (val) async {
          if (val != null) {
            final previous = _selected;
            final errorMessage = context.isArabic
                ? 'تعذر حفظ مستوى الدقة'
                : 'Could not save accuracy level';
            final messenger = ScaffoldMessenger.of(context);
            setState(() => _selected = val);
            final saved = await getIt<SharedPreferences>().setDouble(
              _key,
              _levels[_selected],
            );
            if (!mounted) return;
            if (!saved) {
              setState(() => _selected = previous);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
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

  @override
  void initState() {
    super.initState();
    final prefs = getIt<SharedPreferences>();
    _reviewEnabled = prefs.getBool(_reviewKey) ?? true;
    _streakEnabled = prefs.getBool(_streakKey) ?? true;
    _morningAzkarEnabled = prefs.getBool(_morningAzkarKey) ?? true;
    _eveningAzkarEnabled = prefs.getBool(_eveningAzkarKey) ?? true;
    _dailyDuaEnabled = prefs.getBool(_dailyDuaKey) ?? true;
  }

  Future<void> _toggleReview(bool value) async {
    final previous = _reviewEnabled;
    setState(() {
      _reviewEnabled = value;
      _savingReview = true;
    });

    try {
      final saved = await getIt<SharedPreferences>().setBool(_reviewKey, value);
      if (!saved) {
        throw StateError('Failed to save daily review notification setting');
      }
      if (value) {
        await TaliaNotificationService.instance.scheduleDailyReviewReminder();
      } else {
        await TaliaNotificationService.instance.cancelDailyReviewReminder();
        if (_streakEnabled) {
          await TaliaNotificationService.instance.scheduleStreakProtectionAlert(
            currentStreak: 1,
          );
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _reviewEnabled = previous);
      _showSettingsError(
        context,
        context.isArabic
            ? 'تعذر تحديث تذكير المراجعة'
            : 'Could not update review reminder',
      );
    } finally {
      if (mounted) {
        setState(() => _savingReview = false);
      }
    }
  }

  Future<void> _toggleStreak(bool value) async {
    final previous = _streakEnabled;
    setState(() {
      _streakEnabled = value;
      _savingStreak = true;
    });

    try {
      final saved = await getIt<SharedPreferences>().setBool(_streakKey, value);
      if (!saved) {
        throw StateError('Failed to save streak notification setting');
      }
      if (value) {
        await TaliaNotificationService.instance.scheduleStreakProtectionAlert(
          currentStreak: 1,
        );
      } else {
        await TaliaNotificationService.instance.cancelStreakAlert();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _streakEnabled = previous);
      _showSettingsError(
        context,
        context.isArabic
            ? 'تعذر تحديث تنبيه السلسلة'
            : 'Could not update streak alert',
      );
    } finally {
      if (mounted) {
        setState(() => _savingStreak = false);
      }
    }
  }

  Future<void> _toggleMorningAzkar(bool value) async {
    final previous = _morningAzkarEnabled;
    setState(() {
      _morningAzkarEnabled = value;
      _savingMorningAzkar = true;
    });

    try {
      final saved = await getIt<SharedPreferences>().setBool(
        _morningAzkarKey,
        value,
      );
      if (!saved) {
        throw StateError('Failed to save morning azkar notification setting');
      }
      if (value) {
        await TaliaNotificationService.instance.scheduleMorningAzkarReminder();
      } else {
        await TaliaNotificationService.instance.cancelMorningAzkarReminder();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _morningAzkarEnabled = previous);
      _showSettingsError(
        context,
        context.isArabic
            ? 'تعذر تحديث تذكير أذكار الصباح'
            : 'Could not update morning azkar reminder',
      );
    } finally {
      if (mounted) {
        setState(() => _savingMorningAzkar = false);
      }
    }
  }

  Future<void> _toggleEveningAzkar(bool value) async {
    final previous = _eveningAzkarEnabled;
    setState(() {
      _eveningAzkarEnabled = value;
      _savingEveningAzkar = true;
    });

    try {
      final saved = await getIt<SharedPreferences>().setBool(
        _eveningAzkarKey,
        value,
      );
      if (!saved) {
        throw StateError('Failed to save evening azkar notification setting');
      }
      if (value) {
        await TaliaNotificationService.instance.scheduleEveningAzkarReminder();
      } else {
        await TaliaNotificationService.instance.cancelEveningAzkarReminder();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _eveningAzkarEnabled = previous);
      _showSettingsError(
        context,
        context.isArabic
            ? 'تعذر تحديث تذكير أذكار المساء'
            : 'Could not update evening azkar reminder',
      );
    } finally {
      if (mounted) {
        setState(() => _savingEveningAzkar = false);
      }
    }
  }

  Future<void> _toggleDailyDua(bool value) async {
    final previous = _dailyDuaEnabled;
    setState(() {
      _dailyDuaEnabled = value;
      _savingDailyDua = true;
    });

    try {
      final saved = await getIt<SharedPreferences>().setBool(
        _dailyDuaKey,
        value,
      );
      if (!saved) {
        throw StateError('Failed to save daily dua notification setting');
      }
      if (value) {
        await TaliaNotificationService.instance.scheduleDailyDuaReminder();
      } else {
        await TaliaNotificationService.instance.cancelDailyDuaReminder();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _dailyDuaEnabled = previous);
      _showSettingsError(
        context,
        context.isArabic
            ? 'تعذر تحديث دعاء اليوم'
            : 'Could not update daily dua reminder',
      );
    } finally {
      if (mounted) {
        setState(() => _savingDailyDua = false);
      }
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
            context.l10n.dailyReviewReminder,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.isArabic
                ? 'كل يوم الساعة ٨:٠٠ مساءً'
                : 'Every day at 8:00 PM',
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          value: _reviewEnabled,
          onChanged: _savingReview ? null : _toggleReview,
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
            context.l10n.streakProtection,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.l10n.streakProtectionDesc,
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          value: _streakEnabled,
          onChanged: _savingStreak ? null : _toggleStreak,
          activeThumbColor: primary,
        ),
        Divider(
          height: 0.5,
          color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
          indent: 56,
        ),
        SwitchListTile(
          secondary: Icon(Icons.wb_sunny_rounded, color: primary),
          title: Text(
            context.l10n.morningAzkarReminder,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.isArabic
                ? 'كل يوم الساعة ٦:٠٠ صباحًا'
                : 'Every day at 6:00 AM',
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          value: _morningAzkarEnabled,
          onChanged: _savingMorningAzkar ? null : _toggleMorningAzkar,
          activeThumbColor: primary,
        ),
        Divider(
          height: 0.5,
          color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
          indent: 56,
        ),
        SwitchListTile(
          secondary: Icon(Icons.nightlight_round, color: primary),
          title: Text(
            context.l10n.eveningAzkarReminder,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.isArabic
                ? 'كل يوم الساعة ٦:٠٠ مساءً'
                : 'Every day at 6:00 PM',
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          value: _eveningAzkarEnabled,
          onChanged: _savingEveningAzkar ? null : _toggleEveningAzkar,
          activeThumbColor: primary,
        ),
        Divider(
          height: 0.5,
          color: widget.isDark ? AppColors.darkDivider : AppColors.lightDivider,
          indent: 56,
        ),
        SwitchListTile(
          secondary: Icon(Icons.volunteer_activism_rounded, color: primary),
          title: Text(
            context.l10n.dailyDuaReminder,
            style: AppTypography.bodyMedium.copyWith(color: textColor),
          ),
          subtitle: Text(
            context.isArabic
                ? 'كل يوم الساعة ٩:٠٠ صباحًا'
                : 'Every day at 9:00 AM',
            style: AppTypography.labelSmall.copyWith(color: subtextColor),
          ),
          value: _dailyDuaEnabled,
          onChanged: _savingDailyDua ? null : _toggleDailyDua,
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
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
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
          context.read<ProfileCubit>().updateProfile(
            name: state.user.displayName,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.isArabic
                    ? (_isSignUp
                          ? 'تم إنشاء الحساب بنجاح ✓'
                          : 'تم تسجيل الدخول بنجاح ✓')
                    : (_isSignUp
                          ? 'Account created ✓'
                          : 'Signed in successfully ✓'),
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
                      child: Icon(
                        Icons.person_rounded,
                        color: primary,
                        size: 26,
                      ),
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
                            style: AppTypography.labelSmall.copyWith(
                              color: subtextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_done_rounded,
                                size: 12,
                                color: Colors.green.shade500,
                              ),
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
                color: widget.isDark
                    ? AppColors.darkDivider
                    : AppColors.lightDivider,
                indent: 16,
                endIndent: 16,
              ),
              InkWell(
                onTap: () => _confirmSignOut(context),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.radiusLg),
                ),
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
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        context.l10n.signOut,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.red,
                        ),
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
                      label: context.l10n.signIn,
                      isSelected: !_isSignUp,
                      primary: primary,
                      textColor: textColor,
                      isDark: widget.isDark,
                      onTap: () => setState(() => _isSignUp = false),
                    ),
                    const SizedBox(width: 8),
                    _TabChip(
                      label: context.l10n.signUp,
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
                      label: context.l10n.name,
                      icon: Icons.person_outline_rounded,
                      primary: primary,
                      textColor: textColor,
                      fillColor: fieldFill,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.l10n.enterName;
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
                    label: context.l10n.email,
                    icon: Icons.email_outlined,
                    primary: primary,
                    textColor: textColor,
                    fillColor: fieldFill,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return context.l10n.enterEmail;
                    }
                    if (!v.contains('@') || !v.contains('.')) {
                      return context.l10n.invalidEmail;
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
                  decoration:
                      _inputDecoration(
                        label: context.l10n.password,
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
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return context.isArabic
                          ? 'أدخل كلمة المرور'
                          : 'Enter password';
                    }
                    if (_isSignUp && v.length < 6) {
                      return context.l10n.passwordTooShort;
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
                        ? (context.l10n.createAccount)
                        : (context.l10n.signIn),
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
      labelStyle: AppTypography.labelMedium.copyWith(
        color: textColor.withValues(alpha: 0.6),
      ),
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
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Text(
          context.l10n.signOut,
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
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthCubit>().signOut();
            },
            child: Text(context.l10n.signOut),
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
          color: isSelected
              ? primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? Colors.white12 : Colors.black12),
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
