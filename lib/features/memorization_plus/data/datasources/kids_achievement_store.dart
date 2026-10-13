import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/identity/record_owner_provider.dart';
import '../../domain/services/kids_achievements.dart';

/// Owner-scoped record of the kids milestones already unlocked, with the date
/// each was first reached. Stored as `{ "<id name>": "<ISO date>" }`.
class KidsAchievementStore {
  KidsAchievementStore(this._prefs, this._owner, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final RecordOwnerProvider _owner;
  final DateTime Function() _clock;

  String get _key => 'kids_achievements_${_owner.currentOwnerId}';

  Map<String, DateTime> unlocked() => {
    for (final entry in _storedEntries().entries)
      if (entry.value is String)
        if (DateTime.tryParse(entry.value as String) case final date?)
          entry.key: date.toUtc(),
  };

  /// Every stored `{id: value}` pair, including ids this build's catalog does
  /// not know (written by a newer build) and values it cannot read.
  Map<String, Object?> _storedEntries() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
    } catch (_) {
      return {};
    }
  }

  /// Evaluates the milestones and stores any reached for the first time.
  /// Entries already stored are never dropped, so a milestone unlocked by a
  /// newer build survives a sync from an older one.
  Future<List<KidsAchievement>> sync(KidsAchievementInputs inputs) async {
    final stored = unlocked();
    final all = KidsAchievementCatalog.evaluate(
      inputs,
      now: _clock().toUtc(),
      unlocked: stored,
    );
    final merged = _storedEntries();
    var changed = false;
    for (final achievement in all) {
      final unlockedAt = achievement.unlockedAt;
      if (unlockedAt != null && !stored.containsKey(achievement.id.name)) {
        merged[achievement.id.name] = unlockedAt.toIso8601String();
        changed = true;
      }
    }
    if (changed) await _prefs.setString(_key, jsonEncode(merged));
    return all;
  }
}
