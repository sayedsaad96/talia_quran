import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/home_contextual_slot.dart';

class HomeSlotSnoozeStore {
  HomeSlotSnoozeStore(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const prefix = 'home_slot_snooze_';
  static const signInLegacyKey = 'sign_in_nudge_dismissed';
  static const tutorialLegacyKey = 'home_tutorial_prompt_seen';

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  bool isSnoozed(HomeSlotKind kind) {
    try {
      _migrateLegacy(kind);
      final raw = _prefs.getString('$prefix${kind.name}');
      if (raw == null) return false;
      final until = DateTime.tryParse(raw);
      return until != null && until.isAfter(_now());
    } catch (_) {
      return false;
    }
  }

  Future<void> snooze(
    HomeSlotKind kind, {
    Duration duration = const Duration(days: 7),
  }) {
    final until = _now().add(duration);
    return _prefs.setString('$prefix${kind.name}', until.toIso8601String());
  }

  void _migrateLegacy(HomeSlotKind kind) {
    if (kind == HomeSlotKind.signIn && (_prefs.getBool(signInLegacyKey) ?? false)) {
      if (!_prefs.containsKey('$prefix${kind.name}')) {
        _prefs.setString(
          '$prefix${kind.name}',
          _now().add(const Duration(days: 7)).toIso8601String(),
        );
      }
      _prefs.remove(signInLegacyKey);
    }
    if (kind == HomeSlotKind.tutorial &&
        (_prefs.getBool(tutorialLegacyKey) ?? false)) {
      if (!_prefs.containsKey('$prefix${kind.name}')) {
        _prefs.setString(
          '$prefix${kind.name}',
          _now().add(const Duration(days: 30)).toIso8601String(),
        );
      }
      _prefs.remove(tutorialLegacyKey);
    }
  }
}
