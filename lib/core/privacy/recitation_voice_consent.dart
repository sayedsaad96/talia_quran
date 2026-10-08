import 'package:shared_preferences/shared_preferences.dart';

/// Prominent disclosure for speech-based recitation checks.
///
/// Recitation audio goes to the operating system's speech recognizer, which
/// may process it off the device. Google Play's User Data policy needs that
/// explained, and accepted, before the microphone permission is requested,
/// so every speech path calls [ensure] first. A declined disclosure leaves
/// the microphone untouched and the caller falls back to self-grading.
class RecitationVoiceConsent {
  RecitationVoiceConsent(this._prefs, {required Future<bool> Function() ask})
    : _ask = ask;

  /// Bump the version when the disclosure text changes materially, so users
  /// see the new wording once.
  static const prefsKey = 'recitation_voice_disclosure_v1_accepted';

  final SharedPreferences _prefs;
  final Future<bool> Function() _ask;
  Future<bool>? _pending;

  bool get isAccepted => _prefs.getBool(prefsKey) ?? false;

  /// True when the user accepted the disclosure, now or earlier. Concurrent
  /// callers share one dialog.
  Future<bool> ensure() {
    if (isAccepted) return Future.value(true);
    return _pending ??= _askOnce().whenComplete(() => _pending = null);
  }

  Future<bool> _askOnce() async {
    final accepted = await _ask();
    if (accepted) await _prefs.setBool(prefsKey, true);
    return accepted;
  }
}
