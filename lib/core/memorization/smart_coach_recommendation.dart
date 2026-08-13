import 'package:equatable/equatable.dart';

/// Why the coach surfaced this recommendation (for UI copy + tests).
enum SmartCoachRecommendationKind {
  reviewDueNear,
  reviewDueFar,
  memorizedReviewDue,
  reviewWeakAyah,
  continueDailyPlan,
  memorizeNewAyahs,
  kidsCurrentMission,
  continueV2Session,
}

/// Machine-readable explanation code for the recommendation.
///
/// Intentionally mirrors [SmartCoachRecommendationKind] values, but is
/// kept as a separate type so that:
/// - UI copy keys, analytics events, and test assertions can all depend on
///   a stable, documented code rather than inferring meaning from [kind].
/// - Future codes can diverge from [kind] without a breaking change.
///
/// Localization remains at the UI boundary — no raw strings here.
enum SmartCoachExplanationCode {
  /// Ayah rated weak and now due for review.
  weakAyahDue,

  /// Ayah is in its near-revision window and due.
  nearRevisionDue,

  /// Ayah is past its near-revision window and due.
  farRevisionDue,

  /// Memorized ayah has drifted and needs a retention review.
  memorizedRetentionDue,

  /// User started today's plan but has not finished it.
  continueDailyPlan,

  /// New ayahs are waiting to be memorized in the daily plan.
  newAyahsAvailable,

  /// V2 Session has ayahs pending or in remediation.
  continueV2Session,

  /// Child profile has an active memorization mission.
  kidsMissionAvailable,
}

/// Read-only coach output. Does not persist or mutate progress stores.
class SmartCoachRecommendation extends Equatable {
  const SmartCoachRecommendation({
    required this.kind,
    required this.route,
    this.surahId,
    this.startAyah,
    this.endAyah,
    this.completedCount,
    this.totalCount,
    this.explanationCode,
  });

  final SmartCoachRecommendationKind kind;
  final String route;
  final int? surahId;
  final int? startAyah;
  final int? endAyah;
  final int? completedCount;
  final int? totalCount;

  /// Optional machine-readable explanation code for tests, analytics, and
  /// future UI extensibility. Null when the recommendation was constructed
  /// without an explicit code (e.g. in legacy test helpers).
  final SmartCoachExplanationCode? explanationCode;

  @override
  List<Object?> get props => [
    kind,
    route,
    surahId,
    startAyah,
    endAyah,
    completedCount,
    totalCount,
    explanationCode,
  ];
}
