import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_notification_tiles.dart';
import '../../widgets/settings_subpage_scaffold.dart';

/// Reminders grouped by purpose: general, memorization, worship, and progress.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: context.l10n.settingsSectionProgressAchievements,
      children: [
        SettingsGroup(
          children: [
            NotificationSettingTile(isDark: context.isDark),
          ],
        ),
      ],
    );
  }
}
