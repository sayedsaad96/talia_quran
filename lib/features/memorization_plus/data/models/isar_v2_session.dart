// lib/features/memorization_plus/data/models/isar_v2_session.dart
//
// Isar collection for V2 session persistence.
// Stores only the minimal state needed to resume a session after app kill.
// Complex objects (hintTracker, failureTracker) are serialized as
// comma-separated strings to avoid Isar embedded-object complexity.

import 'package:isar/isar.dart';

import '../../../../core/memorization/review_record_identity.dart';
import '../../domain/entities/kids_session_policy.dart';

part 'isar_v2_session.g.dart';

@collection
class IsarV2Session {
  Id id = Isar.autoIncrement;

  /// Account + audience + surah identity. Nullable only for legacy rows.
  ///
  /// Legacy rows are intentionally not claimed by whichever account opens the
  /// app next; recovery is handled as an explicit verification task.
  @Index(unique: true, replace: true)
  String? sessionKey;

  /// Opaque stable id shared by evidence events for this resumable session.
  /// Null is accepted only for pre-event-sourcing rows and is backfilled on
  /// first read/write by [V2SessionLocalDatasource].
  @Index()
  String? sessionId;

  String? ownerId;

  int audienceIndex = MemorizationAudience.adult.index;

  @Index()
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
  List<int> get blockAyahNumbers => _parsePositiveCsv(blockAyahNumbersCsv);

  @ignore
  Set<int> get passedAyahNumbers =>
      _parsePositiveCsv(passedAyahNumbersCsv).toSet();

  /// Returns failure counts as `Map<ayahNumber, count>`.
  @ignore
  Map<int, int> get failureCounts {
    return _parseCountMap(failureCountsCsv);
  }

  /// Returns hint levels as `Map<ayahNumber, hintLevelIndex>`.
  @ignore
  Map<int, int> get hintLevels {
    return _parseCountMap(hintLevelsCsv);
  }

  /// Invalid persisted CSV never partially advances a session. A malformed
  /// block returns an empty list so the caller starts a fresh safe block;
  /// malformed pass/failure/hint entries are ignored rather than throwing.
  static List<int> _parsePositiveCsv(String raw) {
    if (raw.trim().isEmpty) return const [];
    final parsed = <int>[];
    for (final token in raw.split(',')) {
      final value = int.tryParse(token.trim());
      if (value == null || value <= 0) return const [];
      parsed.add(value);
    }
    if (parsed.toSet().length != parsed.length) return const [];
    return parsed;
  }

  static Map<int, int> _parseCountMap(String raw) {
    if (raw.trim().isEmpty) return const {};
    final result = <int, int>{};
    for (final entry in raw.split(',')) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final key = int.tryParse(parts[0].trim());
      final value = int.tryParse(parts[1].trim());
      if (key == null || key <= 0 || value == null || value < 0) continue;
      result[key] = value;
    }
    return result;
  }

  // ── Factory ──────────────────────────────────────────────

  static String keyFor({
    required String ownerId,
    required MemorizationAudience audience,
    required int surahId,
  }) => '$ownerId|${audience.name}|$surahId';
  static IsarV2Session create({
    required int surahId,
    required List<int> blockAyahNumbers,
    required int currentAyahIndex,
    required int phaseIndex,
    required Set<int> passedAyahNumbers,
    required Map<int, int> failureCounts,
    required Map<int, int> hintLevels,
    required bool blockReviewRequired,
    String? sessionId,
    String ownerId = ReviewRecordIdentity.localOwnerId,
    MemorizationAudience audience = MemorizationAudience.adult,
  }) {
    return IsarV2Session()
      ..sessionKey = keyFor(
        ownerId: ownerId,
        audience: audience,
        surahId: surahId,
      )
      ..sessionId = sessionId
      ..ownerId = ownerId
      ..audienceIndex = audience.index
      ..surahId = surahId
      ..blockAyahNumbersCsv = blockAyahNumbers.join(',')
      ..currentAyahIndex = currentAyahIndex
      ..phaseIndex = phaseIndex
      ..passedAyahNumbersCsv = passedAyahNumbers.join(',')
      ..failureCountsCsv = failureCounts.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',')
      ..hintLevelsCsv = hintLevels.entries
          .map((e) => '${e.key}:${e.value}')
          .join(',')
      ..blockReviewRequired = blockReviewRequired
      ..savedAt = DateTime.now().toUtc();
  }
}
