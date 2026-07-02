abstract final class JourneyFeatureFlags {
  /// When true, the new `UnifiedJourneyEngine` takes over the primary
  /// hero action on the Home page, replacing the legacy conditional cards.
  /// Set to true permanently in Sprint D.
  static bool unifiedJourneyEnabled = true;
}
