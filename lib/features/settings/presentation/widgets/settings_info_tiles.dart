import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import 'settings_section.dart';

class TutorialGuideTile extends StatelessWidget {
  const TutorialGuideTile({super.key, required this.isDark});
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
            SettingsTrailingChevron(color: subtextColor),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyTile extends StatelessWidget {
  const PrivacyPolicyTile({super.key, required this.isDark});
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
            SettingsTrailingChevron(color: subtextColor),
          ],
        ),
      ),
    );
  }
}

class AboutTile extends StatelessWidget {
  const AboutTile({super.key, required this.isDark});
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
