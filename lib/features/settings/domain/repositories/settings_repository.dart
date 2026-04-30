/// ARCH-3 FIX: SettingsRepository abstracts access to user-configurable settings,
/// removing the need to inject [SharedPreferences] directly into feature cubits.
abstract class SettingsRepository {
  /// Returns the user's configured similarity threshold for recitation evaluation.
  /// Defaults to 0.85 (medium difficulty) if not set.
  double getSimilarityThreshold();
}
