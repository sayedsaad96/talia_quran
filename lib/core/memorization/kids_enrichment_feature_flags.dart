import 'package:shared_preferences/shared_preferences.dart';

import '../experience/rollout_manifest.dart';

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

  /// البند 23 — مُغطّى بـ ChildProgressPanel (قائمة الشهادات القابلة للطباعة والمشاركة)؛ لا يقرؤه شيء
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
  monthlyReport,

  /// Phase 2 — guardian planning hints for the linked child.
  remotePlan,

  /// Phase 2 — remote milestone gifts.
  remotePromise,

  /// Phase 2 — fixed encouragement messages and approved stickers.
  encouragements;

  String get storageKey => '${KidsEnrichmentFlags.keyPrefix}$name';
}

/// Rollout switches for [KidsEnrichmentFeature]. A stored value wins;
/// otherwise [KidsEnrichmentFlags.fromPreferences] uses the shipped default in
/// [RolloutManifest]. An unreadable value counts as off. Turning one off never touches the existing kids journey,
/// [KidsHifzFeatureFlags] or data the feature already stored.
///
/// The keys are device-level rollout switches (like
/// `use_review_evidence_transport`): they are deliberately outside the
/// account-owned key inventory in `AccountDataReset`, so an account switch
/// does not flip them.
class KidsEnrichmentFlags {
  const KidsEnrichmentFlags(this._readBool);

  /// Reads from [prefs], then the shipped default; read failures are "off".
  KidsEnrichmentFlags.fromPreferences(SharedPreferences prefs)
    : _readBool = ((key) =>
          prefs.getBool(key) ?? RolloutManifest.defaultFor(key));

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
