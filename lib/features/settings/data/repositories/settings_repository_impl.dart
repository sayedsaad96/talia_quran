import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';

/// ARCH-3 FIX: Implementation backed by [SharedPreferences].
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  static const similarityThresholdKey = 'similarity_threshold';

  final SharedPreferences _prefs;

  @override
  double getSimilarityThreshold() =>
      levelThreshold(_prefs.getDouble(similarityThresholdKey));

  /// Maps a stored value to its accuracy level's threshold.
  static double levelThreshold(double? stored) {
    if (stored == null) return SettingsRepository.balancedPassThreshold;
    if (stored <= SettingsRepository.lenientPassThreshold) {
      return SettingsRepository.lenientPassThreshold;
    }
    if (stored >= SettingsRepository.strictPassThreshold) {
      return SettingsRepository.strictPassThreshold;
    }
    return SettingsRepository.balancedPassThreshold;
  }
}
