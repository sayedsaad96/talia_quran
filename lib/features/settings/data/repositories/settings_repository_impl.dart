import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

/// ARCH-3 FIX: Implementation backed by [SharedPreferences].
/// HifzSessionCubit now depends on [SettingsRepository] instead of
/// directly on [SharedPreferences], keeping the Cubit testable and
/// decoupled from platform specifics.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  static const _similarityThresholdKey = 'similarity_threshold';
  static const _defaultThreshold = 0.85;

  final SharedPreferences _prefs;

  @override
  double getSimilarityThreshold() =>
      _prefs.getDouble(_similarityThresholdKey) ?? _defaultThreshold;
}
