import 'package:equatable/equatable.dart';

import '../entities/kids_session_log.dart';
import '../entities/kids_session_policy.dart';
import 'kids_return_policy.dart';

/// Counts behind the effort milestones, derived only from the child's saved
/// session logs. A log exists only once a session was committed, so a failed
/// attempt on its own never reaches these numbers.
class KidsEffortAchievementInputs extends Equatable {
  const KidsEffortAchievementInputs({
    this.completedReviews = 0,
    this.retriedSuccesses = 0,
    this.comebacks = 0,
  });

  /// Review sessions (due or linked) the child completed.
  final int completedReviews;

  /// Sessions that succeeded after more than one attempt.
  final int retriedSuccesses;

  /// Sessions that followed a break of three or more local days.
  final int comebacks;

  @override
  List<Object?> get props => [completedReviews, retriedSuccesses, comebacks];
}

/// Pure: the same logs always give the same inputs, and a log repeated by a
/// retry or a cloud merge is counted once (logs are keyed by id).
KidsEffortAchievementInputs buildKidsEffortInputs(
  Iterable<KidsSessionLog> logs,
) {
  final byId = <String, KidsSessionLog>{};
  for (final log in logs) {
    byId.putIfAbsent(log.id, () => log);
  }
  final unique = byId.values.toList()
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

  var reviews = 0;
  var retried = 0;
  var comebacks = 0;
  KidsSessionLog? previous;
  for (final log in unique) {
    if (log.missionType == KidsMissionType.dueReview ||
        log.missionType == KidsMissionType.linkedReview) {
      reviews++;
    }
    if (log.attemptCount > 1) retried++;
    if (previous != null &&
        kidsIsReturningAfterBreak(previous.completedAt, log.completedAt)) {
      comebacks++;
    }
    previous = log;
  }
  return KidsEffortAchievementInputs(
    completedReviews: reviews,
    retriedSuccesses: retried,
    comebacks: comebacks,
  );
}
