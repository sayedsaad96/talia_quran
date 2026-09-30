import 'package:equatable/equatable.dart';

import '../entities/memorization_entities.dart';

/// Today's age-band mission budget, derived from the local kids session log.
///
/// Every surface that proposes or opens a kids mission (home, completion
/// "Next", the session gate) reads the same budget, so a mission is only ever
/// offered when it can actually start (N2/N3). A zero cap means "unlimited",
/// which keeps every consumer fail-open when the policy or logs are missing.
final class KidsDailyBudget extends Equatable {
  const KidsDailyBudget({
    this.newAyahsCompletedToday = 0,
    this.maxNewAyahsPerDay = 0,
    this.dueReviewsCompletedToday = 0,
    this.maxDueReviewsPerDay = 0,
    this.sessionSecondsToday = 0,
  });

  factory KidsDailyBudget.fromLogs({
    required Iterable<KidsSessionLog> logs,
    required KidsSessionPolicy? policy,
    required DateTime now,
  }) {
    final local = now.toLocal();
    final startOfDay = DateTime(local.year, local.month, local.day);
    var newToday = 0;
    var reviewsToday = 0;
    var secondsToday = 0;
    for (final log in logs) {
      if (log.completedAt.isBefore(startOfDay)) continue;
      secondsToday += log.durationSeconds;
      if (log.missionType == KidsMissionType.newMemorization) newToday++;
      if (log.missionType == KidsMissionType.dueReview) reviewsToday++;
    }
    return KidsDailyBudget(
      newAyahsCompletedToday: newToday,
      maxNewAyahsPerDay: policy?.maxNewAyahs ?? 0,
      dueReviewsCompletedToday: reviewsToday,
      maxDueReviewsPerDay: policy?.maxDueReviews ?? 0,
      sessionSecondsToday: secondsToday,
    );
  }

  static const unlimited = KidsDailyBudget();

  final int newAyahsCompletedToday;
  final int maxNewAyahsPerDay;
  final int dueReviewsCompletedToday;
  final int maxDueReviewsPerDay;

  /// Time spent in kids sessions today, from the logs (K36).
  final int sessionSecondsToday;

  /// Today's sessions reached a goal of [goalMinutes] — a gentle "that's
  /// enough for today", never a block. A zero goal never triggers (K36).
  bool sessionGoalReached(int goalMinutes) =>
      goalMinutes > 0 && sessionSecondsToday >= goalMinutes * 60;

  /// Today's new-memorization quota is used up: no new ayah may start.
  bool get newAyahLimitReached =>
      maxNewAyahsPerDay > 0 && newAyahsCompletedToday >= maxNewAyahsPerDay;

  /// The same budget with no new-ayah quota — asks "would new work remain
  /// if today's quota were not spent?" (K18).
  KidsDailyBudget get withoutNewAyahCap => KidsDailyBudget(
    newAyahsCompletedToday: newAyahsCompletedToday,
    dueReviewsCompletedToday: dueReviewsCompletedToday,
    maxDueReviewsPerDay: maxDueReviewsPerDay,
    sessionSecondsToday: sessionSecondsToday,
  );

  /// Today's due-review budget is spent. Keeps a persistent STT
  /// false-negative loop (weak ratings) from starving new memorization.
  bool get dueReviewBudgetExhausted =>
      maxDueReviewsPerDay > 0 &&
      dueReviewsCompletedToday >= maxDueReviewsPerDay;

  @override
  List<Object?> get props => [
    newAyahsCompletedToday,
    maxNewAyahsPerDay,
    dueReviewsCompletedToday,
    maxDueReviewsPerDay,
    sessionSecondsToday,
  ];
}
