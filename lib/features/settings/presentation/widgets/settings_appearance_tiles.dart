import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/locale_cubit.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/pure_black_cubit.dart';
import '../../../../core/theme/theme_cubit.dart';

/// Light, Dark, Pure black (OLED) and System as four peer choices.
///
/// Pure black is not a separate switch: it is a distinct dark variant, so it
/// is chosen here and only ever changes which dark palette is used. Light and
/// System leave the remembered dark variant untouched.
class ThemeSettingTile extends StatelessWidget {
  const ThemeSettingTile({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<PureBlackCubit, bool>(
          builder: (context, pureBlack) {
            final primary = context.tokens.accent;
            final l10n = context.l10n;

            Widget option({
              required String label,
              required IconData icon,
              required bool selected,
              required VoidCallback onTap,
            }) => Expanded(
              child: ThemeOption(
                label: label,
                icon: icon,
                isSelected: selected,
                color: primary,
                isDark: isDark,
                onTap: onTap,
              ),
            );

            const gap = SizedBox(width: AppSpacing.xs);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  option(
                    label: l10n.lightMode,
                    icon: TaliaIcons.sun,
                    selected: themeMode == ThemeMode.light,
                    onTap: () => unawaited(
                      context.read<ThemeCubit>().setTheme(ThemeMode.light),
                    ),
                  ),
                  gap,
                  option(
                    label: l10n.darkMode,
                    icon: TaliaIcons.moon,
                    selected: themeMode == ThemeMode.dark && !pureBlack,
                    onTap: () => unawaited(_selectDark(context, oled: false)),
                  ),
                  gap,
                  option(
                    label: l10n.pureBlackTheme,
                    icon: TaliaIcons.contrast,
                    selected: themeMode == ThemeMode.dark && pureBlack,
                    onTap: () => unawaited(_selectDark(context, oled: true)),
                  ),
                  gap,
                  option(
                    label: l10n.systemDefault,
                    icon: TaliaIcons.themeAuto,
                    selected: themeMode == ThemeMode.system,
                    onTap: () => unawaited(
                      context.read<ThemeCubit>().setTheme(ThemeMode.system),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Sets the palette first so the switch never flashes the wrong dark.
  static Future<void> _selectDark(
    BuildContext context, {
    required bool oled,
  }) async {
    final pureBlackCubit = context.read<PureBlackCubit>();
    final themeCubit = context.read<ThemeCubit>();
    await pureBlackCubit.setEnabled(oled);
    await themeCubit.setTheme(ThemeMode.dark);
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
    final textColor = context.tokens.textPrimary;

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 104 * MediaQuery.textScalerOf(context).scale(1),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.2 : 0.11)
                : context.tokens.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.7)
                  : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
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
        final primary = context.tokens.accent;

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: LocaleOption(
                  label: context.l10n.arabic,
                  sublabel: 'العربية',
                  flag: '🇸🇦',
                  isSelected: isAr,
                  color: primary,
                  isDark: isDark,
                  onTap: () =>
                      context.read<LocaleCubit>().setLocale(const Locale('ar')),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: LocaleOption(
                  label: 'English',
                  sublabel: context.l10n.english,
                  flag: '🇬🇧',
                  isSelected: !isAr,
                  color: primary,
                  isDark: isDark,
                  onTap: () =>
                      context.read<LocaleCubit>().setLocale(const Locale('en')),
                ),
              ),
            ],
          ),
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
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textHint;

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 78 * MediaQuery.textScalerOf(context).scale(1),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.18 : 0.09)
                : context.tokens.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.65)
                  : Colors.transparent,
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.tokens.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(flag, style: AppTypography.titleLarge),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          color: textColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        sublabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: subtextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(TaliaIcons.checkCircleFilled, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
