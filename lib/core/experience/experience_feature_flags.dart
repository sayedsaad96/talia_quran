import 'package:shared_preferences/shared_preferences.dart';

import '../identity/record_owner_provider.dart';
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

  /// Rollout flags first (as [ExperienceFlags.fromPreferences]), then the
  /// signed-in owner's own on/off choice written by the «مزايا التطبيق» page
  /// (`feature_pref_<name>|<ownerId>`, on unless turned off). A feature shows
  /// only when both layers allow it, so every existing read site honours the
  /// user's switch. The owner is read on each call, so an account switch
  /// takes effect immediately. An unreadable choice counts as on.
  ExperienceFlags.withUserPreferences(
    SharedPreferences prefs,
    RecordOwnerProvider owner,
  ) : _readBool = ((key) {
        final rollout = prefs.getBool(key) ?? RolloutManifest.defaultFor(key);
        if (rollout != true || !key.startsWith(keyPrefix)) return rollout;
        try {
          final name = key.substring(keyPrefix.length);
          final ownerId = owner.currentOwnerId;
          return prefs.getBool('$userPreferenceKeyPrefix$name|$ownerId') ??
              true;
        } catch (_) {
          return true;
        }
      });

  static const keyPrefix = 'experience_flag_';

  /// Per-owner user choice keys: `feature_pref_<name>|<ownerId>`.
  static const userPreferenceKeyPrefix = 'feature_pref_';

  final bool? Function(String key) _readBool;

  bool isEnabled(ExperienceFeature feature) {
    try {
      return _readBool(feature.storageKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}
