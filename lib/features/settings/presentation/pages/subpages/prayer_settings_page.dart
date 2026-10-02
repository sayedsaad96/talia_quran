import 'package:flutter/material.dart';

import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../prayer_companion/presentation/widgets/prayer_companion_settings_section.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_prayer_notification_tiles.dart';
import '../../widgets/settings_prayer_tiles.dart';
import '../../widgets/settings_subpage_scaffold.dart';

/// Prayer times and Prayer Companion, kept in two separate groups.
class PrayerSettingsPage extends StatefulWidget {
  const PrayerSettingsPage({super.key});

  @override
  State<PrayerSettingsPage> createState() => _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends State<PrayerSettingsPage> {
  final _prayerTimesSectionKey = GlobalKey();

  void _scrollToPrayerTimes(BuildContext context) {
    final targetContext = _prayerTimesSectionKey.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SettingsSubpageScaffold(
      title: context.l10n.homePrayerTimes,
      children: [
        SettingsGroup(
          key: _prayerTimesSectionKey,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              // Rebuilding the page refreshes the alerts section below,
              // which reads prayer readiness when it builds.
              child: PrayerTimesSettingsSection(
                isDark: isDark,
                onChanged: () {
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: context.l10n.settingsRemindersPrayer,
          children: [
            PrayerNotificationSettingsSection(
              isDark: isDark,
              onConfigurePrayerTimes: () => _scrollToPrayerTimes(context),
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
