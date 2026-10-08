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

  Map<String, DateTime> unlocked() {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            if (DateTime.tryParse(entry.value as String) case final date?)
              entry.key as String: date.toUtc(),
      };
    } catch (_) {
      return {};
    }
  }

  /// Evaluates the milestones and stores any reached for the first time.
  Future<List<KidsAchievement>> sync(KidsAchievementInputs inputs) async {
    final stored = unlocked();
    final all = KidsAchievementCatalog.evaluate(
      inputs,
      now: _clock().toUtc(),
      unlocked: stored,
    );
    final reached = {
      for (final achievement in all)
        achievement.id.name: ?achievement.unlockedAt,
    };
    if (reached.length != stored.length) {
      await _prefs.setString(
        _key,
        jsonEncode({
          for (final entry in reached.entries)
            entry.key: entry.value.toIso8601String(),
        }),
      );
    }
    return all;
  }
}
