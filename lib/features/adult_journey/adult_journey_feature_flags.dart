import 'package:shared_preferences/shared_preferences.dart';

/// Independently switchable parts of Adult Journey Package 1
/// (`docs/superpowers/plans/2026-10-11-adult-journey-package-1.md`).
///
/// Names are stable and each storage key is derived from the [name], so never
/// rename or repurpose one.
enum AdultJourneyFeature {
  /// Optional goal/experience personalization. Required by every other part.
  personalization,

  /// 5/10/20-minute "time for today" suggestions.
  todayBudget,

  /// Gentle-return invitation after seven or more days away.
  gentleReturn;

  String get storageKey => '${AdultJourneyFlags.keyPrefix}$name';
}

/// Rollout switches for [AdultJourneyFeature], following
/// `KidsEnrichmentFlags`. Every part is off until explicitly enabled, and a
/// missing, mistyped or unreadable value counts as off. Turning one off
/// restores the existing Home and never deletes stored preferences.
///
/// The keys are device-level rollout switches: [keyPrefix] deliberately does
/// not start with the account-owned `adult_journey_v1_` prefix, so an account
/// switch does not flip them.
class AdultJourneyFlags {
  const AdultJourneyFlags(this._readBool);

  /// Reads from [prefs], treating any read failure as "off".
  AdultJourneyFlags.fromPreferences(SharedPreferences prefs)
    : _readBool = prefs.getBool;

  static const keyPrefix = 'adult_journey_flag_';

  final bool? Function(String key) _readBool;

  /// Applies the dependency rules: personalization gates the package.
  bool isEnabled(AdultJourneyFeature feature) {
    if (!_raw(AdultJourneyFeature.personalization)) return false;
    return _raw(feature);
  }

  /// Gentle-return actions that pick a time also need [todayBudget].
  bool get gentleReturnTimeActionsEnabled =>
      isEnabled(AdultJourneyFeature.gentleReturn) &&
      isEnabled(AdultJourneyFeature.todayBudget);

  bool _raw(AdultJourneyFeature feature) {
    try {
      return _readBool(feature.storageKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}
