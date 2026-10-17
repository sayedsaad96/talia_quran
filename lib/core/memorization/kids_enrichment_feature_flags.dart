import 'package:shared_preferences/shared_preferences.dart';

/// Independently switchable parts of the kids enrichment roadmap
/// (`docs/superpowers/plans/2026-10-11-kids-enrichment-roadmap.md`).
///
/// Names are stable and the storage key of each value is derived from its
/// [name], so never rename or repurpose one. Values for deferred tasks exist
/// so the inventory stays complete; nothing reads them until they ship.
enum KidsEnrichmentFeature {
  /// T1 — educational home-mission templates.
  homeMissionTemplates,

  /// T2 — effort and review achievements.
  effortAchievements,

  /// T3 — weekly guardian summary.
  weeklyCoaching,

  /// T4 — shared family practice.
  familyPractice,

  /// T5 — approved meaning lessons (blocked on licensed content).
  learningLessons,

  /// T6 — spoken guidance (deferred).
  spokenGuidance,

  /// T7 — learning-support profile.
  supportProfile,

  /// T8 — targeted help after a struggle.
  supportActions,

  /// T9 — short learning games.
  learningGames,

  /// T10 — world growth from saved evidence.
  worldGrowth,

  /// T11 — offline weekly pack (deferred).
  weeklyPack,

  /// T12 — personal recitation portfolio (deferred).
  recitationPortfolio,

  /// البند 23 من خارطة التميّز
  guardianCertificates,

  /// البند 24 من خارطة التميّز
  bedtimeListening,

  /// البند 21 من خارطة التميّز
  guardianPromise,

  /// البند 20 من خارطة التميّز
  guardianRecitation,

  /// البند 25 من خارطة التميّز
  guardianMilestones,

  /// البند 27 من خارطة التميّز
  monthlyReport;

  String get storageKey => '${KidsEnrichmentFlags.keyPrefix}$name';
}

/// Rollout switches for [KidsEnrichmentFeature]. Every feature is off until
/// it is explicitly enabled, and a missing, mistyped or unreadable value
/// counts as off. Turning one off never touches the existing kids journey,
/// [KidsHifzFeatureFlags] or data the feature already stored.
///
/// The keys are device-level rollout switches (like
/// `use_review_evidence_transport`): they are deliberately outside the
/// account-owned key inventory in `AccountDataReset`, so an account switch
/// does not flip them.
class KidsEnrichmentFlags {
  const KidsEnrichmentFlags(this._readBool);

  /// Reads from [prefs], treating any read failure as "off".
  KidsEnrichmentFlags.fromPreferences(SharedPreferences prefs)
    : _readBool = prefs.getBool;

  static const keyPrefix = 'kids_enrichment_';

  final bool? Function(String key) _readBool;

  bool isEnabled(KidsEnrichmentFeature feature) {
    try {
      return _readBool(feature.storageKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}
