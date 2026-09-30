import 'package:shared_preferences/shared_preferences.dart';

/// How the adult reader draws the Mushaf page (N13).
///
/// Only the tajweed colouring is configurable today; the Quran text itself
/// is always the canonical QCF rendering either way.
abstract final class ReaderDisplayPreferences {
  static const _tajweedKey = 'reader_tajweed_enabled';

  /// Tajweed colours stay on unless the reader turned them off.
  static bool tajweedEnabled(SharedPreferences prefs) =>
      prefs.getBool(_tajweedKey) ?? true;

  static Future<void> setTajweedEnabled(
    SharedPreferences prefs,
    bool enabled,
  ) => prefs.setBool(_tajweedKey, enabled);
}
