import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/experience/experience_feature_flags.dart';
import '../../../../../core/experience/feature_preferences.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/home_widget/home_widget_publisher.dart';
import '../../../../../core/icons/talia_icons.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/services/notification_scheduler.dart';
import '../../../../azkar/domain/services/after_prayer_azkar_window.dart';
import '../../../../../core/router/app_router.dart';
import '../../widgets/home_widget_options.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_subpage_scaffold.dart';
import '../../widgets/settings_switch_tile.dart';

/// «مزايا التطبيق»: every optional feature that ships in this release, one
/// row each — icon, name, a one-line benefit and a single switch, with a
/// «try it» action where the feature has a place to open. Features whose
/// rollout flag is off never appear here, so no switch can fail to work.
/// Rows whose control already lives elsewhere (the reader menu) link there
/// instead of carrying a second switch.
class FeaturesSettingsPage extends StatefulWidget {
  const FeaturesSettingsPage({super.key});

  @override
  State<FeaturesSettingsPage> createState() => _FeaturesSettingsPageState();
}

class _FeaturesSettingsPageState extends State<FeaturesSettingsPage> {
  FeaturePreferences? get _store => getIt.isRegistered<FeaturePreferences>()
      ? getIt<FeaturePreferences>()
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsSubpageScaffold(
      title: l10n.settingsFeaturesPageTitle,
      children: [
        for (final group in _FeatureGroup.values)
          SettingsGroup(
            title: group.title(l10n),
            children: _rows(context, group),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TextButton(
            onPressed: _store == null
                ? null
                : () async {
                    final l10n = context.l10n;
                    await _store!.resetToDefaults();
                    if (!mounted) return;
                    setState(() {});
                    if (getIt.isRegistered<NotificationScheduler>()) {
                      unawaited(
                        getIt<NotificationScheduler>().refreshNotifications(
                          l10n,
                          force: true,
                        ),
                      );
                    }
                    if (getIt.isRegistered<HomeWidgetPublisher>()) {
                      unawaited(_refreshHomeWidget());
                    }
                  },
            child: Text(l10n.settingsRestoreDefaults),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  List<Widget> _rows(BuildContext context, _FeatureGroup group) {
    final l10n = context.l10n;
    final isDark = context.isDark;
    final store = _store;
    final rows = [
      // Only what ships in this release; a hidden feature shows no switch.
      for (final row in _FeatureRow.values)
        if (row.group == group && (store?.isAvailable(row.feature) ?? false))
          row,
    ];
    return [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0) SettingsDivider(isDark: isDark, indent: 0),
        SettingsSwitchTile(
          icon: rows[i].icon,
          title: rows[i].title(l10n),
          subtitle: rows[i].subtitle(l10n),
          value: store?.isEnabled(rows[i].feature) ?? true,
          showSwitch: rows[i].hasSwitch,
          onChanged: store == null || !rows[i].hasSwitch
              ? null
              : (value) => _setFeature(store, rows[i].feature, value),
          // A switched-off feature has nothing to try.
          onTry:
              rows[i].openPath == null ||
                  !(store?.isEnabled(rows[i].feature) ?? true)
              ? null
              : () => _open(rows[i].openPath!),
          tryLabel: rows[i].openPath == null ? null : l10n.settingsFeaturesTry,
        ),
        if (rows[i] == _FeatureRow.homeWidget &&
            (store?.isEnabled(rows[i].feature) ?? false))
          const HomeWidgetOptions(),
      ],
    ];
  }

  void _open(String path) => context.push(path);

  /// Stores the choice, then makes it take effect now: notifications that the
  /// feature gates are rescheduled, and the home widget is re-published.
  Future<void> _setFeature(
    FeaturePreferences store,
    ExperienceFeature feature,
    bool value,
  ) async {
    final l10n = context.l10n;
    await store.setEnabled(feature, value);
    if (!mounted) return;
    setState(() {});
    if (getIt.isRegistered<NotificationScheduler>()) {
      unawaited(
        getIt<NotificationScheduler>().refreshNotifications(l10n, force: true),
      );
    }
    if (feature == ExperienceFeature.homeWidget &&
        getIt.isRegistered<HomeWidgetPublisher>()) {
      unawaited(_refreshHomeWidget());
    }
  }

  Future<void> _refreshHomeWidget() async {
    try {
      await getIt<HomeWidgetPublisher>().refresh();
    } catch (_) {
      // The next start or resume re-reads the switch.
    }
  }
}

enum _FeatureGroup {
  reading,
  memorization,
  azkar,
  together,
  home;

  String title(AppLocalizations l10n) => switch (this) {
    reading => l10n.settingsFeaturesGroupReading,
    memorization => l10n.settingsFeaturesGroupMemorization,
    azkar => l10n.settingsFeaturesGroupAzkar,
    together => l10n.settingsFeaturesGroupTogether,
    home => l10n.settingsFeaturesGroupHome,
  };
}

enum _FeatureRow {
  readerRepeat(
    _FeatureGroup.reading,
    ExperienceFeature.readerRepeat,
    TaliaIcons.repeat,
    AppRoutes.quran,
  ),
  ayahNotes(
    _FeatureGroup.reading,
    ExperienceFeature.ayahNotes,
    TaliaIcons.note,
    AppRoutes.quranNotes,
  ),
  audioDownloads(
    _FeatureGroup.reading,
    ExperienceFeature.audioDownloads,
    TaliaIcons.download,
    AppRoutes.audioDownloads,
  ),
  // Controlled where it lives (the reader overflow menu), so this row only
  // links there instead of adding a second switch (T0 inventory).
  strengthOverlay(
    _FeatureGroup.memorization,
    ExperienceFeature.strengthOverlay,
    TaliaIcons.sparkle,
    AppRoutes.quran,
    hasSwitch: false,
  ),
  forgettingForecast(
    _FeatureGroup.memorization,
    ExperienceFeature.forgettingForecast,
    TaliaIcons.trendingDown,
    AppRoutes.progress,
  ),
  // Appears by itself after prayers; no dedicated page to open.
  prayerReview(
    _FeatureGroup.memorization,
    ExperienceFeature.prayerReview,
    TaliaIcons.prayer,
    null,
  ),
  handsFreeReview(
    _FeatureGroup.memorization,
    ExperienceFeature.handsFreeReview,
    TaliaIcons.mic,
    AppRoutes.handsFreeReview,
  ),
  afterPrayerAzkar(
    _FeatureGroup.azkar,
    ExperienceFeature.afterPrayerAzkar,
    TaliaIcons.star,
    null,
  ),
  groupKhatmah(
    _FeatureGroup.together,
    ExperienceFeature.groupKhatmah,
    TaliaIcons.family,
    AppRoutes.groupKhatmah,
  ),
  homeWidget(
    _FeatureGroup.home,
    ExperienceFeature.homeWidget,
    TaliaIcons.phone,
    null,
  );

  const _FeatureRow(
    this.group,
    this.feature,
    this.icon,
    this.tryPath, {
    this.hasSwitch = true,
  });

  final _FeatureGroup group;
  final ExperienceFeature feature;
  final IconData icon;
  final String? tryPath;
  final bool hasSwitch;

  /// The path «try it» opens; the azkar row encodes its subcategory lazily
  /// (Uri.encodeQueryComponent is not a const expression).
  String? get openPath => this == _FeatureRow.afterPrayerAzkar
      ? '/azkar/general?sub=${Uri.encodeQueryComponent(afterPrayerAzkarSubcategory)}'
      : tryPath;

  String title(AppLocalizations l10n) => switch (this) {
    readerRepeat => l10n.settingsFeatureReaderRepeatTitle,
    ayahNotes => l10n.settingsFeatureAyahNotesTitle,
    audioDownloads => l10n.settingsFeatureAudioDownloadsTitle,
    strengthOverlay => l10n.settingsFeatureStrengthOverlayTitle,
    forgettingForecast => l10n.settingsFeatureForgettingForecastTitle,
    prayerReview => l10n.settingsFeaturePrayerReviewTitle,
    handsFreeReview => l10n.settingsFeatureHandsFreeTitle,
    afterPrayerAzkar => l10n.settingsFeatureAfterPrayerAzkarTitle,
    groupKhatmah => l10n.settingsFeatureGroupKhatmahTitle,
    homeWidget => l10n.settingsFeatureHomeWidgetTitle,
  };

  String subtitle(AppLocalizations l10n) => switch (this) {
    readerRepeat => l10n.settingsFeatureReaderRepeatSubtitle,
    ayahNotes => l10n.settingsFeatureAyahNotesSubtitle,
    audioDownloads => l10n.settingsFeatureAudioDownloadsSubtitle,
    strengthOverlay => l10n.settingsFeatureStrengthOverlaySubtitle,
    forgettingForecast => l10n.settingsFeatureForgettingForecastSubtitle,
    prayerReview => l10n.settingsFeaturePrayerReviewSubtitle,
    handsFreeReview => l10n.settingsFeatureHandsFreeSubtitle,
    afterPrayerAzkar => l10n.settingsFeatureAfterPrayerAzkarSubtitle,
    groupKhatmah => l10n.settingsFeatureGroupKhatmahSubtitle,
    homeWidget => l10n.settingsFeatureHomeWidgetSubtitle,
  };
}
