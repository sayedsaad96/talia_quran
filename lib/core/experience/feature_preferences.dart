import 'package:shared_preferences/shared_preferences.dart';

import '../identity/record_owner_provider.dart';
import 'experience_feature_flags.dart';

/// User-level on/off choice for an [ExperienceFeature], stored per owner the
/// way `RamadanCardDismissStore` stores its dismissals. Two layers decide
/// whether a feature appears:
///
/// 1. availability — the raw rollout flag ([ExperienceFlags.fromPreferences] /
///    `RolloutManifest`), which must NOT already include the user's choice;
/// 2. preference — this store, on unless the user turns it off.
///
/// The app-wide `getIt<ExperienceFlags>` is built with
/// [ExperienceFlags.withUserPreferences], so existing read sites honour both
/// layers. Turning a preference off hides the feature and never deletes its
/// data.
class FeaturePreferences {
  FeaturePreferences(this._prefs, this._owner, this._flags);

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final ExperienceFlags _flags;

  static const keyPrefix = ExperienceFlags.userPreferenceKeyPrefix;

  static String keyFor(ExperienceFeature feature, String ownerId) =>
      '$keyPrefix${feature.name}|$ownerId';

  /// Availability layer: the feature ships in this build.
  bool isAvailable(ExperienceFeature feature) {
    try {
      return _flags.isEnabled(feature);
    } catch (_) {
      return false;
    }
  }

  /// The user's stored choice, on by default (also when unreadable).
  bool isEnabled(ExperienceFeature feature) {
    try {
      return _prefs.getBool(keyFor(feature, _owner.currentOwnerId)) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Owner captured once so an account switch mid-call cannot misfile it.
  Future<void> setEnabled(ExperienceFeature feature, bool value) {
    final key = keyFor(feature, _owner.currentOwnerId);
    return _prefs.setBool(key, value);
  }

  /// Both layers on: the feature is available and the user wants it.
  bool isVisible(ExperienceFeature feature) =>
      isAvailable(feature) && isEnabled(feature);

  /// Removes this owner's stored choices, so every feature falls back to on.
  /// Used by the page's «restore defaults» button.
  Future<void> resetToDefaults() async {
    final ownerId = _owner.currentOwnerId;
    final suffix = '|$ownerId';
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(keyPrefix) && k.endsWith(suffix))
        .toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
