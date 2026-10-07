import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
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
    final primary = context.tokens.accent;
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(TaliaIcons.mushaf, color: primary, size: 22),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.l10n.tutorialGuideSubtitle,
                    style: AppTypography.labelMedium.copyWith(
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
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                TaliaIcons.shield,
                color: AppColors.info,
                size: 22,
              ),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.l10n.settingsPrivacyPolicySubtitle,
                    style: AppTypography.labelMedium.copyWith(
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

class SourcesLicensesTile extends StatelessWidget {
  const SourcesLicensesTile({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;

    return InkWell(
      onTap: () => context.push(AppRoutes.sourcesLicenses),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(TaliaIcons.library, color: primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.sourcesLicensesTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.l10n.sourcesLicensesSubtitle,
                    style: AppTypography.labelMedium.copyWith(
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
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final version = state.appVersion ?? '1.0.0';
        final buildNumber = state.appBuildNumber ?? '1';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: isDark
                ? AppColors.heroGradientDark
                : AppColors.heroGradientLight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_new.png',
                        width: 44,
                        height: 44,
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
                            color: Colors.white,
                            fontFamily: context.isArabic ? 'Amiri' : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                'v$version ($buildNumber)',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.taliaDescription,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A settings tile that shares the Talia app with friends via share_plus.
class ShareAppTile extends StatelessWidget {
  const ShareAppTile({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = context.tokens.accent;
    final textColor = context.tokens.textPrimary;
    final subtextColor = context.tokens.textSecondary;

    return InkWell(
      onTap: () {
        SharePlus.instance.share(ShareParams(text: context.l10n.shareAppText));
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(TaliaIcons.share, color: primary, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.shareApp,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.isArabic
                        ? 'شارك تجربة تالية مع أهلك وأصدقائك'
                        : 'Share the Talia experience with friends',
                    style: AppTypography.labelMedium.copyWith(
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(TaliaIcons.externalLink, size: 18, color: subtextColor),
          ],
        ),
      ),
    );
  }
}
