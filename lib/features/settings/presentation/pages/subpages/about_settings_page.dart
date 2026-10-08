import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_info_tiles.dart';
import '../../widgets/settings_section.dart';
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
          children: [PrivacyPolicyTile(isDark: isDark)],
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
