import 'package:flutter/material.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../widgets/settings_notification_tiles.dart';
import '../../widgets/settings_section.dart';

/// Dedicated subpage for Notifications & Daily Reminders.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.settingsSectionProgressAchievements),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          SettingsSection(
            title: context.l10n.settingsSectionProgressAchievements,
            accentColor: accentColor,
            icon: Icons.notifications_active_rounded,
            collapsible: false,
            children: [
              NotificationSettingTile(isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}
