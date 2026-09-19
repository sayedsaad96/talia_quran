import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/cubits/auth_cubit.dart';
import '../../widgets/settings_account_tiles.dart';
import '../../widgets/settings_info_tiles.dart';
import '../../widgets/settings_section.dart';

/// Dedicated subpage for Help, Privacy, and About Talia.
class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.settingsSectionAboutTalia),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // Help & Support
          SettingsSection(
            title: context.l10n.settingsSectionHelpTutorial,
            accentColor: accentColor,
            icon: Icons.help_outline_rounded,
            collapsible: false,
            children: [
              TutorialGuideTile(isDark: isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Privacy & Security
          SettingsSection(
            title: context.l10n.settingsSectionPrivacySecurity,
            accentColor: accentColor,
            icon: Icons.security_rounded,
            collapsible: false,
            children: [
              PrivacyPolicyTile(isDark: isDark),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState is! AuthAuthenticated) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      SettingsDivider(isDark: isDark),
                      DeleteAccountTile(
                        isDark: isDark,
                        email: authState.user.email,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // About Talia & Share
          SettingsSection(
            title: context.l10n.settingsSectionAboutTalia,
            accentColor: accentColor,
            icon: Icons.info_outline_rounded,
            collapsible: false,
            children: [
              AboutTile(isDark: isDark),
              SettingsDivider(isDark: isDark),
              ShareAppTile(isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}
