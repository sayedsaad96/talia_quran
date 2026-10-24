import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/experience/experience_feature_flags.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/memorization/kids_enrichment_feature_flags.dart';
import '../../../../core/memorization/kids_hifz_feature_flags.dart';
import '../../../../core/services/notification_scheduler.dart';
import '../../../adult_journey/adult_journey_feature_flags.dart';

/// Debug-only developer page: one switch per flag of every rollout family.
/// Each switch writes straight to SharedPreferences with the exact key the
/// family's flag reads. Titles are fixed technical English on purpose.
class LabsFlagsPage extends StatefulWidget {
  const LabsFlagsPage({super.key, required this.prefs, this.onFlagChanged});

  final SharedPreferences prefs;

  /// Runs after every switch. Defaults to rescheduling notifications, since
  /// several flags gate reminders that are only cancelled on a refresh.
  final void Function(BuildContext context)? onFlagChanged;

  @override
  State<LabsFlagsPage> createState() => _LabsFlagsPageState();
}

class _LabsFlagsPageState extends State<LabsFlagsPage> {
  static final _groups = <String, List<(String label, String key)>>{
    'KidsEnrichmentFeature': [
      for (final f in KidsEnrichmentFeature.values) (f.name, f.storageKey),
    ],
    'AdultJourneyFeature': [
      for (final f in AdultJourneyFeature.values) (f.name, f.storageKey),
    ],
    'KidsHifzFeatureFlags': [
      ('enabled', KidsHifzFeatureFlags.enabledKey),
      ('quranJourney', KidsHifzFeatureFlags.quranJourneyKey),
    ],
    'ExperienceFeature': [
      for (final f in ExperienceFeature.values) (f.name, f.storageKey),
    ],
  };

  /// Keys whose flag reads `true` when unset, so the switch shows the real
  /// effective state.
  static const _defaultOn = {KidsHifzFeatureFlags.quranJourneyKey};

  Future<void> _set(String key, bool value) async {
    await widget.prefs.setBool(key, value);
    if (!mounted) return;
    setState(() {});
    (widget.onFlagChanged ?? _refreshNotifications)(context);
  }

  static void _refreshNotifications(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (l10n == null || !getIt.isRegistered<NotificationScheduler>()) return;
    unawaited(
      getIt<NotificationScheduler>().refreshNotifications(l10n, force: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Labs (debug)')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in _groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final (label, key) in entry.value)
                SwitchListTile(
                  key: ValueKey('labs_flag_$key'),
                  title: Text(label),
                  subtitle: Text(key),
                  value: widget.prefs.getBool(key) ?? _defaultOn.contains(key),
                  onChanged: (v) => _set(key, v),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
