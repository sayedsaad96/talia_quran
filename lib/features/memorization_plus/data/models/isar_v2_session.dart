// lib/features/memorization_plus/data/models/isar_v2_session.dart
//
// Isar collection for V2 session persistence.
// Stores only the minimal state needed to resume a session after app kill.
// Complex objects (hintTracker, failureTracker) are serialized as
// comma-separated strings to avoid Isar embedded-object complexity.

import 'package:isar/isar.dart';

part 'isar_v2_session.g.dart';

@collection
class IsarV2Session {
  Id id = Isar.autoIncrement;

  /// One active session per surah — use surahId as the unique key.
  @Index(unique: true, replace: true)
  late int surahId;

  /// JSON-encoded ayah numbers in the current block, e.g. "1,2,3,4,5"
  late String blockAyahNumbersCsv;

  /// Index into [blockAyahNumbersCsv] for the currently active ayah.
  late int currentAyahIndex;

  /// Index of V2SessionPhase enum value (see session_phase.dart).
  late int phaseIndex;

  /// Ayah numbers that individually passed recitation, comma-separated.
  late String passedAyahNumbersCsv;

  /// Failure counts per ayah, format: "ayahNumber:count,ayahNumber:count"
  late String failureCountsCsv;

  /// Hint levels per ayah, format: "ayahNumber:levelIndex,..."
  late String hintLevelsCsv;

  /// Whether block review is required for this session.
  late bool blockReviewRequired;

  /// UTC timestamp when this session was last saved.
  late DateTime savedAt;

  // ── Helpers (ignored by Isar generator) ────────────────

  @ignore
  List<int> get blockAyahNumbers => blockAyahNumbersCsv.isEmpty
      ? []
      : blockAyahNumbersCsv.split(',').map(int.parse).toList();

  @ignore
  Set<int> get passedAyahNumbers => passedAyahNumbersCsv.isEmpty
      ? {}
      : passedAyahNumbersCsv.split(',').map(int.parse).toSet();

  /// Returns failure counts as `Map<ayahNumber, count>`.
  @ignore
  Map<int, int> get failureCounts {
    if (failureCountsCsv.isEmpty) return {};
    return Map.fromEntries(
      failureCountsCsv.split(',').map((entry) {
        final parts = entry.split(':');
        return MapEntry(int.parse(parts[0]), int.parse(parts[1]));
      }),
    );
  }

  /// Returns hint levels as `Map<ayahNumber, hintLevelIndex>`.
  @ignore
  Map<int, int> get hintLevels {
    if (hintLevelsCsv.isEmpty) return {};
    return Map.fromEntries(
      hintLevelsCsv.split(',').map((entry) {
        final parts = entry.split(':');
        return MapEntry(int.parse(parts[0]), int.parse(parts[1]));
      }),
    );
  }

  // ── Factory ──────────────────────────────────────────────

  static IsarV2Session create({
    required int surahId,
    required List<int> blockAyahNumbers,
    required int currentAyahIndex,
    required int phaseIndex,
    required Set<int> passedAyahNumbers,
    required Map<int, int> failureCounts,
    required Map<int, int> hintLevels,
    required bool blockReviewRequired,
  }) {
    return IsarV2Session()
      ..surahId = surahId
      ..blockAyahNumbersCsv = blockAyahNumbers.join(',')
      ..currentAyahIndex = currentAyahIndex
      ..phaseIndex = phaseIndex
      ..passedAyahNumbersCsv = passedAyahNumbers.join(',')
      ..failureCountsCsv =
          failureCounts.entries.map((e) => '${e.key}:${e.value}').join(',')
      ..hintLevelsCsv =
          hintLevels.entries.map((e) => '${e.key}:${e.value}').join(',')
      ..blockReviewRequired = blockReviewRequired
      ..savedAt = DateTime.now().toUtc();
  }
}
