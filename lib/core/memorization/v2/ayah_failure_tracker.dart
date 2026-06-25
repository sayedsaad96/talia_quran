// lib/core/memorization/v2/ayah_failure_tracker.dart

import 'package:equatable/equatable.dart';

/// Failure threshold for Weak Ayah classification (Product Rules §14.5).
const int kWeakAyahFailureThreshold = 3;

/// Remediation escalation levels (Product Rules §14.4).
enum V2RemediationLevel {
  standard, // 1st failure — replay + re-memorize
  guided, // 2nd failure — additional guided memorization
  weakAyah, // 3rd+ failure — Smart Coach signal
}

/// Immutable failure record for one ayah in a session.
final class V2AyahFailureRecord extends Equatable {
  const V2AyahFailureRecord({
    required this.surahId,
    required this.ayahNumber,
    required this.failureCount,
    required this.lastFailedAt,
  }) : assert(failureCount > 0);

  final int surahId;
  final int ayahNumber;
  final int failureCount;
  final DateTime lastFailedAt;

  String get ayahKey => '$surahId:$ayahNumber';

  bool get isWeak => failureCount >= kWeakAyahFailureThreshold;

  V2RemediationLevel get remediationLevel => switch (failureCount) {
    1 => V2RemediationLevel.standard,
    2 => V2RemediationLevel.guided,
    _ => V2RemediationLevel.weakAyah,
  };

  V2AyahFailureRecord increment() => V2AyahFailureRecord(
    surahId: surahId,
    ayahNumber: ayahNumber,
    failureCount: failureCount + 1,
    lastFailedAt: DateTime.now().toUtc(),
  );

  @override
  List<Object?> get props => [surahId, ayahNumber, failureCount, lastFailedAt];
}

/// Tracks all recitation failures within a single V2 session.
final class V2AyahFailureTracker extends Equatable {
  const V2AyahFailureTracker({Map<String, V2AyahFailureRecord>? records})
    : _records = records ?? const {};

  final Map<String, V2AyahFailureRecord> _records;

  static const empty = V2AyahFailureTracker();

  int failureCountFor(int surahId, int ayahNumber) =>
      _records['$surahId:$ayahNumber']?.failureCount ?? 0;

  bool isWeak(int surahId, int ayahNumber) =>
      _records['$surahId:$ayahNumber']?.isWeak ?? false;

  V2RemediationLevel remediationLevelFor(int surahId, int ayahNumber) =>
      _records['$surahId:$ayahNumber']?.remediationLevel ??
      V2RemediationLevel.standard;

  V2AyahFailureTracker recordFailure({
    required int surahId,
    required int ayahNumber,
  }) {
    final key = '$surahId:$ayahNumber';
    final existing = _records[key];
    final updated = existing == null
        ? V2AyahFailureRecord(
            surahId: surahId,
            ayahNumber: ayahNumber,
            failureCount: 1,
            lastFailedAt: DateTime.now().toUtc(),
          )
        : existing.increment();

    return V2AyahFailureTracker(records: {..._records, key: updated});
  }

  Iterable<V2AyahFailureRecord> get allFailures => _records.values;
  Iterable<V2AyahFailureRecord> get weakAyahs =>
      _records.values.where((r) => r.isWeak);
  Set<String> get weakAyahKeys => weakAyahs.map((r) => r.ayahKey).toSet();
  bool get hasWeakAyahs => _records.values.any((r) => r.isWeak);
  int get totalFailures =>
      _records.values.fold(0, (sum, r) => sum + r.failureCount);

  @override
  List<Object?> get props => [_records];
}
