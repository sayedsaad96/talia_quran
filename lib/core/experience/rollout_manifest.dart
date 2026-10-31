import '../../features/adult_journey/adult_journey_feature_flags.dart';
import '../memorization/kids_enrichment_feature_flags.dart';
import '../memorization/kids_hifz_feature_flags.dart';
import 'experience_feature_flags.dart';

enum RolloutStage { off, on }

/// The shipped default of one rollout flag. An `on` entry names the section
/// of `docs/release/rollout-evidence.md` that records why it is on; an `off`
/// entry names the reason it stays off.
final class RolloutEntry {
  const RolloutEntry(
    this.key,
    this.stage, {
    this.evidence,
    this.reason,
    this.requires = const [],
  });

  final String key;
  final RolloutStage stage;
  final String? evidence;
  final String? reason;

  /// Keys whose default must also be on for this default to apply.
  final List<String> requires;
}

/// Shipped defaults for every rollout flag of the four families. A value the
/// user stored (Labs, debug builds) always wins over the default. Turning a
/// line back to `off` in a later release hides the feature and keeps its data.
abstract final class RolloutManifest {
  static const _enableAll = 'owner-2026-10-24-enable-all';
  static const _quranJourney = 'owner-2026-10-18-quran-journey';

  static RolloutEntry _on(String key, {List<String> requires = const []}) =>
      RolloutEntry(
        key,
        RolloutStage.on,
        evidence: _enableAll,
        requires: requires,
      );

  static RolloutEntry _off(String key, String reason) =>
      RolloutEntry(key, RolloutStage.off, reason: reason);

  static final List<RolloutEntry> entries = List.unmodifiable([
    for (final f in ExperienceFeature.values) _experience(f),
    for (final f in KidsEnrichmentFeature.values) _kids(f),
    for (final f in AdultJourneyFeature.values) _adultJourney(f),
    _on(KidsHifzFeatureFlags.enabledKey),
    const RolloutEntry(
      KidsHifzFeatureFlags.quranJourneyKey,
      RolloutStage.on,
      evidence: _quranJourney,
    ),
  ]);

  static RolloutEntry _experience(ExperienceFeature f) => switch (f) {
    ExperienceFeature.similarAyahTrainer => RolloutEntry(
      f.storageKey,
      RolloutStage.on,
      evidence: 'owner-2026-10-30-similar-ayahs-30',
    ),
    ExperienceFeature.tabletSpread => _off(
      f.storageKey,
      'Not wired into the reader (H3 waits on the H2 tablet measurement).',
    ),
    _ => _on(f.storageKey),
  };

  static RolloutEntry _kids(KidsEnrichmentFeature f) => switch (f) {
    KidsEnrichmentFeature.learningLessons => _off(
      f.storageKey,
      'T5: blocked on licensed meaning content.',
    ),
    KidsEnrichmentFeature.spokenGuidance ||
    KidsEnrichmentFeature.weeklyPack ||
    KidsEnrichmentFeature.recitationPortfolio => _off(
      f.storageKey,
      'Deferred by the owner (T6, T11, T12).',
    ),
    KidsEnrichmentFeature.guardianCertificates => _off(
      f.storageKey,
      'No effect: item 23 is covered by ChildProgressPanel, which has no flag.',
    ),
    _ => _on(f.storageKey),
  };

  static RolloutEntry _adultJourney(AdultJourneyFeature f) => switch (f) {
    AdultJourneyFeature.personalization => _on(f.storageKey),
    _ => _on(
      f.storageKey,
      requires: [AdultJourneyFeature.personalization.storageKey],
    ),
  };

  static RolloutEntry? entryFor(String key) {
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }

  /// True only for an `on` entry whose every requirement defaults on too.
  /// Unknown keys are off.
  static bool defaultFor(String key) => _defaultFor(key, const {});

  static bool _defaultFor(String key, Set<String> visiting) {
    if (visiting.contains(key)) return false;
    final entry = entryFor(key);
    if (entry == null || entry.stage != RolloutStage.on) return false;
    final next = {...visiting, key};
    return entry.requires.every((required) => _defaultFor(required, next));
  }
}
