import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/experience/experience_feature_flags.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/icons/talia_icons.dart';
import '../../../../../core/router/app_router.dart';
import '../../widgets/settings_backup_tile.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_info_tiles.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_trust_tile.dart';
import '../../widgets/settings_subpage_scaffold.dart';

/// Help, privacy, and about Talia as three separate groups.
class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l10n = context.l10n;

    return SettingsSubpageScaffold(
      title: l10n.settingsSectionAboutTalia,
      children: [
        SettingsGroup(
          title: l10n.settingsSectionHelpTutorial,
          children: [TutorialGuideTile(isDark: isDark)],
        ),
        SettingsGroup(
          title: l10n.settingsSectionPrivacySecurity,
          children: [
            if (getIt.isRegistered<ExperienceFlags>() &&
                getIt<ExperienceFlags>().isEnabled(
                  ExperienceFeature.trustCenter,
                )) ...[
              const TrustCenterTile(),
              SettingsDivider(isDark: isDark),
            ],
            if (getIt.isRegistered<ExperienceFlags>() &&
                getIt<ExperienceFlags>().isEnabled(
                  ExperienceFeature.localBackup,
                )) ...[
              const BackupTile(),
              SettingsDivider(isDark: isDark),
            ],
            PrivacyPolicyTile(isDark: isDark),
            SettingsDivider(isDark: isDark),
            // The Tanzil licence requires the attribution and tanzil.net link
            // to stay reachable in the app.
            const SourcesLicensesTile(),
            if (kDebugMode) ...[
              SettingsDivider(isDark: isDark),
              // Developer-only rollout switches; absent from release builds.
              ListTile(
                leading: const Icon(TaliaIcons.tune),
                title: const Text('Labs (debug)'),
                onTap: () => context.push(AppRoutes.labsFlags),
              ),
            ],
          ],
        ),
        SettingsGroup(
          title: l10n.settingsSectionAboutTalia,
          children: [
            AboutTile(isDark: isDark),
            SettingsDivider(isDark: isDark),
            ShareAppTile(isDark: isDark),
          ],
        ),
      ],
    );
  }
}
