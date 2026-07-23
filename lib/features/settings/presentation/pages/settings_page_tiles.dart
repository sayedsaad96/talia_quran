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
    final border = (isDark ? AppColors.darkDivider : AppColors.lightDivider)
        .withValues(alpha: isDark ? 0.55 : 0.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              letterSpacing: 0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Material(
          color: surface,
          elevation: isDark ? 0 : 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: border, width: 0.6),
            ),
            child: Column(children: children),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.025, end: 0);
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
      indent: 64,
    );
  }
}

class _SettingsTrailingChevron extends StatelessWidget {
  const _SettingsTrailingChevron({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      context.isArabic
          ? Icons.arrow_back_ios_rounded
          : Icons.arrow_forward_ios_rounded,
      size: 16,
      color: color,
    );
  }
}

class _SettingsInlineHeader extends StatelessWidget {
  const _SettingsInlineHeader({
    required this.isDark,
    required this.icon,
    required this.title,
  });

  final bool isDark;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final iconColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemorizationPathSummaryTile extends StatelessWidget {
  const _MemorizationPathSummaryTile({
    required this.isDark,
    required this.profile,
  });

  final bool isDark;
  final MemorizationProfile? profile;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final selectedPath = profile?.selectedPath;
    final hasPath = selectedPath != null;
    final title = switch (selectedPath) {
      MemorizationPath.adult => context.l10n.memorizationPathAdultsTitle,
      MemorizationPath.child => context.l10n.memorizationPathKidsTitle,
      _ => context.l10n.settingsMemorizationPathNotSelected,
    };
    final subtitle = switch (selectedPath) {
      MemorizationPath.adult => context.l10n.memorizationPathAdultsDesc,
      MemorizationPath.child => context.l10n.memorizationPathKidsDesc,
      _ => context.l10n.settingsMemorizationPathNotSelectedDesc,
    };

    final content = Padding(
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
              color: hasPath
                  ? primary.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.route_rounded,
              color: hasPath ? primary : AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.memorizationPath,
                  style: AppTypography.labelSmall.copyWith(
                    color: subtextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: hasPath ? textColor : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(color: subtextColor),
                ),
              ],
            ),
          ),
          if (!hasPath) const _SettingsTrailingChevron(color: AppColors.error),
        ],
      ),
    );

    if (!hasPath) {
      return InkWell(
        onTap: () => context.push(AppRoutes.memorizationPlus),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: content,
      );
    }

    return content;
  }
}

class _ParentDashboardTile extends StatelessWidget {
  const _ParentDashboardTile({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isGuest = authState is! AuthAuthenticated;
    final subtitle = isGuest
        ? context.l10n.parentDashboardGuestSubtitle
        : context.l10n.parentDashboardSubtitle;

    return InkWell(
      onTap: () => unawaited(_openParentDashboard(context)),
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
                    context.l10n.parentDashboardTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _SettingsTrailingChevron(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openParentDashboard(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      unawaited(context.push(AppRoutes.login));
      return;
    }
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).parentDashboardLocation();
    if (context.mounted) unawaited(context.push(location));
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
                  context.l10n.parentGuardianMode,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.l10n.parentModeSubtitle,
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
          builder: (dialogContext) => const _ResetMemorizationPathDialog(),
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
                    context.l10n.resetMemorizationPathTileTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    context.l10n.resetMemorizationPathTileSubtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _SettingsTrailingChevron(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetMemorizationPathDialog extends StatefulWidget {
  const _ResetMemorizationPathDialog();

  @override
  State<_ResetMemorizationPathDialog> createState() =>
      _ResetMemorizationPathDialogState();
}

class _ResetMemorizationPathDialogState
    extends State<_ResetMemorizationPathDialog> {
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final confirmText = context.l10n.settingsResetPathConfirmPhrase;
    final canConfirm = _confirmController.text.trim() == confirmText;

    return AlertDialog(
      title: Text(
        context.l10n.resetMemorizationPathQuestion,
        style: const TextStyle(fontFamily: 'Amiri'),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.resetMemorizationIdentityWarning),
            const SizedBox(height: AppSpacing.md),
            _SettingsChecklistLine(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF2D8E4C),
              text: context.l10n.settingsResetPathKeeps,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SettingsChecklistLine(
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              text: context.l10n.settingsResetPathChanges,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.settingsResetPathInstruction),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _confirmController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: confirmText),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: canConfirm ? () => Navigator.pop(context, true) : null,
          child: Text(context.l10n.confirmResetMemorizationPath),
        ),
      ],
    );
  }
}

class _SettingsChecklistLine extends StatelessWidget {
  const _SettingsChecklistLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
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
            _SettingsDivider(isDark: isDark),
            _ThemeOption(
              label: context.l10n.darkMode,
              icon: Icons.dark_mode_rounded,
              isSelected: themeMode == ThemeMode.dark,
              color: const Color(0xFF2D5A8E),
              isDark: isDark,
              onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.dark),
            ),
            _SettingsDivider(isDark: isDark),
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
              label: context.l10n.arabic,
              sublabel: 'Arabic',
              flag: '🇸🇦',
              isSelected: isAr,
              color: primary,
              isDark: isDark,
              onTap: () =>
                  context.read<LocaleCubit>().setLocale(const Locale('ar')),
            ),
            _SettingsDivider(isDark: isDark),
            _LocaleOption(
              label: 'English',
              sublabel: context.l10n.english,
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
      onTap: () => context.push(AppRoutes.tutorialGuide),
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
                    context.l10n.tutorialGuideTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    context.l10n.tutorialGuideSubtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            _SettingsTrailingChevron(color: subtextColor),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPolicyTile extends StatelessWidget {
  const _PrivacyPolicyTile({required this.isDark});
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
      onTap: () => context.push(AppRoutes.privacyPolicy),
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
              child: Icon(Icons.privacy_tip_outlined, color: primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.privacyPolicy,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    context.l10n.settingsPrivacyPolicySubtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            _SettingsTrailingChevron(color: subtextColor),
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

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final version = state.appVersion ?? '—';
        final buildNumber = state.appBuildNumber ?? '—';

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_new.png',
                    width: 46,
                    height: 46,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.settingsAppBrand,
                      style: AppTypography.titleLarge.copyWith(
                        color: textColor,
                      ),
                    ),
                    Text(
                      context.l10n.settingsVersion(version),
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                    Text(
                      context.l10n.settingsBuild(buildNumber),
                      style: AppTypography.bodySmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.taliaDescription,
                      style: AppTypography.labelSmall.copyWith(
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                context.l10n.arabicNameHint,
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
              _showSettingsError(context, context.l10n.profileSaveError);
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

  Future<void> _select(BuildContext context, int value) async {
    if (value == _selected) return;

    final previous = _selected;
    final errorMessage = context.l10n.accuracySaveError;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _selected = value);

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

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;

    final titles = [
      context.l10n.accuracyEasyTitle,
      context.l10n.accuracyMediumTitle,
      context.l10n.accuracyHardTitle,
    ];
    final descriptions = [
      context.l10n.accuracyEasyDesc,
      context.l10n.accuracyMediumDesc,
      context.l10n.accuracyHardDesc,
    ];
    final percents = [70, 85, 92];
    final colors = [Colors.green, primary, Colors.deepOrange];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mic_rounded, color: primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  context.l10n.accuracyLevel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < 3; i++) ...[
            _AccuracyOptionCard(
              title: titles[i],
              description: descriptions[i],
              percentLabel: context.l10n.accuracyRequiredPercent(percents[i]),
              color: colors[i],
              isDark: widget.isDark,
              isSelected: _selected == i,
              onTap: () => _select(context, i),
            ),
            if (i != 2) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AccuracyOptionCard extends StatelessWidget {
  const _AccuracyOptionCard({
    required this.title,
    required this.description,
    required this.percentLabel,
    required this.color,
    required this.isDark,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final String percentLabel;
  final Color color;
  final bool isDark;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.14 : 0.06),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: color.withValues(alpha: isSelected ? 0.72 : 0.18),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.labelSmall.copyWith(
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                percentLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
        _SettingsDivider(isDark: widget.isDark),
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
        _SettingsDivider(isDark: widget.isDark),
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
        _SettingsDivider(isDark: widget.isDark),
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
        _SettingsDivider(isDark: widget.isDark),
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
        _SettingsDivider(isDark: widget.isDark),
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

// ─── Account Section (Email & Password Auth) ─────────────────────────────────

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({
    required this.isDark,
    required this.icon,
    this.label,
    this.isSignedIn = false,
  });

  final bool isDark;
  final IconData icon;
  final String? label;
  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isSignedIn ? AppColors.primaryGradient : null,
        color: isSignedIn ? null : primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.45),
          width: 1,
        ),
      ),
      child: label == null
          ? Icon(icon, color: primary, size: 28)
          : Text(
              label!,
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

String _accountInitials(AppUser user) {
  final source = user.displayName.trim().isNotEmpty
      ? user.displayName.trim()
      : user.email.trim();
  if (source.isEmpty) return 'T';

  final parts = source
      .split(RegExp(r'\s+'))
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  return source.characters.take(2).toString().toUpperCase();
}

class _AccountSection extends StatefulWidget {
  const _AccountSection({required this.isDark});
  final bool isDark;

  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = widget.isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        } else if (state is AuthAccountDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.settingsAccountDeletedMessage),
              backgroundColor: Colors.green.shade700,
            ),
          );
          context.go(AppRoutes.login);
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
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AccountAvatar(
                      isDark: widget.isDark,
                      icon: Icons.person_rounded,
                      label: _accountInitials(user),
                      isSignedIn: true,
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
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    size: 13,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.l10n.settingsSignedInStatus,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
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
                      Expanded(
                        child: Text(
                          context.l10n.signOut,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // ─── Unauthenticated view (Redirect to Main Login) ───────────
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AccountAvatar(
                    isDark: widget.isDark,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.settingsGuestStatusTitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.settingsGuestStatusSubtitle,
                          style: AppTypography.labelSmall.copyWith(
                            color: subtextColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.login),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text(context.l10n.settingsSignInCreateAccount),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          context.l10n.signOutWarning,
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

class _DeleteAccountTile extends StatelessWidget {
  const _DeleteAccountTile({required this.isDark, required this.email});

  final bool isDark;
  final String email;

  @override
  Widget build(BuildContext context) {
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => _confirmDeleteAccount(context, email),
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
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.settingsDeleteAccountTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    context.l10n.settingsDeleteAccountSubtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            _SettingsTrailingChevron(color: subtextColor),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.settingsDeleteAccountTitle),
        content: Text(context.l10n.settingsDeleteAccountWarning(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().deleteAccount();
    }
  }
}
