/// ARCH-3 FIX: SettingsRepository abstracts access to user-configurable settings,
/// removing the need to inject [SharedPreferences] directly into feature cubits.
abstract class SettingsRepository {
  /// Recitation pass thresholds behind the "Accuracy level" setting.
  static const lenientPassThreshold = 0.70;
  static const balancedPassThreshold = 0.88;
  static const strictPassThreshold = 0.92;

  /// The pass threshold of the accuracy level the user chose. Balanced (the
  /// default) matches the engine's standard threshold; a value stored by an
  /// older build (0.85) also reads as balanced.
  double getSimilarityThreshold();
}
