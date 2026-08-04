import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import 'settings_section.dart';

class ThemeSettingTile extends StatelessWidget {
  const ThemeSettingTile({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final primary = isDark ? AppColors.primaryLight : AppColors.primary;

        return Column(
          children: [
            ThemeOption(
              label: context.l10n.lightMode,
              icon: Icons.light_mode_rounded,
              isSelected: themeMode == ThemeMode.light,
              color: const Color(0xFFFF8C42),
              isDark: isDark,
              onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.light),
            ),
            SettingsDivider(isDark: isDark),
            ThemeOption(
              label: context.l10n.darkMode,
              icon: Icons.dark_mode_rounded,
              isSelected: themeMode == ThemeMode.dark,
              color: const Color(0xFF2D5A8E),
              isDark: isDark,
              onTap: () => context.read<ThemeCubit>().setTheme(ThemeMode.dark),
            ),
            SettingsDivider(isDark: isDark),
            ThemeOption(
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

class ThemeOption extends StatelessWidget {
  const ThemeOption({
    super.key,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : color.withValues(alpha: 0.2),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
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
                      size: 13,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class LocaleSettingTile extends StatelessWidget {
  const LocaleSettingTile({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final isAr = locale.languageCode == 'ar';
        final primary = isDark ? AppColors.primaryLight : AppColors.primary;

        return Column(
          children: [
            LocaleOption(
              label: context.l10n.arabic,
              sublabel: 'العربية',
              flag: '🇸🇦',
              isSelected: isAr,
              color: primary,
              isDark: isDark,
              onTap: () =>
                  context.read<LocaleCubit>().setLocale(const Locale('ar')),
            ),
            SettingsDivider(isDark: isDark),
            LocaleOption(
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

class LocaleOption extends StatelessWidget {
  const LocaleOption({
    super.key,
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
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? color
                      : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Text(flag, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: subtextColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
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
                      size: 13,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
