import 'package:flutter/material.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../prayer_companion/presentation/widgets/prayer_companion_settings_section.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_prayer_tiles.dart';
import '../../widgets/settings_subpage_scaffold.dart';

/// Prayer times and Prayer Companion, kept in two separate groups.
class PrayerSettingsPage extends StatelessWidget {
  const PrayerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SettingsSubpageScaffold(
      title: context.l10n.homePrayerTimes,
      children: [
        SettingsGroup(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: PrayerTimesSettingsSection(isDark: isDark),
            ),
          ],
        ),
        SettingsGroup(
          title: context.l10n.prayerCompanionSettingsTitle,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: PrayerCompanionSettingsSection(isDark: isDark),
            ),
          ],
        ),
      ],
    );
  }
}
