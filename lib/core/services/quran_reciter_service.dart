import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran_reciter.dart';

/// Manages active Quran reciter preference across the app.
class QuranReciterService {
  QuranReciterService(this._prefs) {
    _loadReciter();
  }

  final SharedPreferences _prefs;
  static const String _key = 'quran_selected_reciter_id';

  final ValueNotifier<QuranReciter> _currentReciter = ValueNotifier(
    QuranReciter.alafasy,
  );

  ValueListenable<QuranReciter> get currentReciter => _currentReciter;

  void _loadReciter() {
    final storedId = _prefs.getString(_key);
    final stored = QuranReciter.fromId(storedId);
    _currentReciter.value = stored.isAvailable ? stored : QuranReciter.alafasy;
  }

  Future<void> setReciter(QuranReciter reciter) async {
    reciter.requireAvailable();
    _currentReciter.value = reciter;
    await _prefs.setString(_key, reciter.id);
  }
}
