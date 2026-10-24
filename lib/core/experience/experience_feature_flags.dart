import 'package:shared_preferences/shared_preferences.dart';

import 'rollout_manifest.dart';

/// Independently switchable parts of the roadmap batch A experience rollout.
///
/// Names are stable and each storage key is derived from the [name], so never
/// rename or repurpose one. Values for later items exist so the inventory
/// stays complete; nothing reads them until they ship.
enum ExperienceFeature {
  /// Memorization-strength overlay on the adult reader.
  strengthOverlay,

  /// Repeat controls in the adult reader.
  readerRepeat,

  /// Privacy and trust center.
  trustCenter,

  seasonalRamadan,
  forgettingForecast,
  similarAyahTrainer,
  prayerReview,
  homeWidget,
  handsFreeReview,
  clarityMode,
  groupKhatmah,
  localBackup,
  audioDownloads,
  afterPrayerAzkar,
  ayahNotes,
  tabletSpread,
  hijriYearRecap;

  String get storageKey => '${ExperienceFlags.keyPrefix}$name';
}

/// Rollout switches for [ExperienceFeature]. A stored value wins; otherwise
/// [ExperienceFlags.fromPreferences] falls back to the shipped default in
/// [RolloutManifest]. An unreadable value counts as off. Turning one off
/// restores the previous UI and never deletes data.
class ExperienceFlags {
  /// Reads only [_readBool]: a missing value is off (tests, explicit wiring).
  const ExperienceFlags(this._readBool);

  /// Reads from [prefs], then the shipped default; read failures are "off".
  ExperienceFlags.fromPreferences(SharedPreferences prefs)
    : _readBool = ((key) =>
          prefs.getBool(key) ?? RolloutManifest.defaultFor(key));

  static const keyPrefix = 'experience_flag_';

  final bool? Function(String key) _readBool;

  bool isEnabled(ExperienceFeature feature) {
    try {
      return _readBool(feature.storageKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}
