import 'package:flutter/material.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../prayer_companion/presentation/widgets/prayer_companion_settings_section.dart';
import '../../widgets/settings_prayer_tiles.dart';
import '../../widgets/settings_section.dart';

/// Dedicated subpage for Prayer Times and Prayer Companion settings.
class PrayerSettingsPage extends StatelessWidget {
  const PrayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(context.l10n.homePrayerTimes),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          // Prayer Times Section
          SettingsSection(
            title: context.l10n.homePrayerTimes,
            accentColor: accentColor,
            icon: Icons.schedule_rounded,
            collapsible: false,
            children: [
              PrayerTimesSettingsSection(isDark: isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Prayer Companion Section
          SettingsSection(
            title: context.l10n.prayerCompanionSettingsTitle,
            accentColor: accentColor,
            icon: Icons.favorite_border_rounded,
            collapsible: false,
            children: [
              PrayerCompanionSettingsSection(isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}
