import 'package:equatable/equatable.dart';

import '../entities/kids_session_log.dart';
import '../entities/kids_session_policy.dart';

/// What a guardian can say about the child's last seven local days.
enum KidsWeeklyCoachingStatus {
  /// The device does not hold the child's full history, so no weekly
  /// judgement is made (an unknown week is never shown as a quiet one).
  incompleteHistory,

  /// The child has never completed a session.
  noHistory,

  /// A week with at least one session, or a quiet week after earlier ones.
  ready,
}

/// One practical suggestion, picked from a fixed catalog by explicit
/// evidence. No generated text and no diagnosis.
enum KidsWeeklyCoachingTip {
  listenTogether,
  celebrateEffort,
  keepRhythm,
  addReview,
  startSmall,
}

class KidsWeeklyCoaching extends Equatable {
  const KidsWeeklyCoaching({
    required this.status,
    required this.periodStart,
    required this.periodEnd,
    this.sessions = 0,
    this.activeDays = 0,
    this.reviews = 0,
    this.sessionsWithHints = 0,
    this.retriedSessions = 0,
    this.tip,
  });

  final KidsWeeklyCoachingStatus status;

  /// First and last local calendar day of the window (inclusive, date only).
  final DateTime periodStart;
  final DateTime periodEnd;

  final int sessions;
  final int activeDays;
  final int reviews;
  final int sessionsWithHints;
  final int retriedSessions;
  final KidsWeeklyCoachingTip? tip;

  @override
  List<Object?> get props => [
    status,
    periodStart,
    periodEnd,
    sessions,
    activeDays,
    reviews,
    sessionsWithHints,
    retriedSessions,
    tip,
  ];
}

/// Pure summary of the last seven local calendar days, today included.
///
/// [historyComplete] must be true only when [logs] is the child's whole
/// saved history (the child's own device). Otherwise nothing is concluded.
KidsWeeklyCoaching buildKidsWeeklyCoaching({
  required Iterable<KidsSessionLog> logs,
  required DateTime now,
  required bool historyComplete,
}) {
  final local = now.toLocal();
  final periodEnd = DateTime(local.year, local.month, local.day);
  final periodStart = DateTime(local.year, local.month, local.day - 6);

  if (!historyComplete) {
    return KidsWeeklyCoaching(
      status: KidsWeeklyCoachingStatus.incompleteHistory,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  final byId = <String, KidsSessionLog>{};
  for (final log in logs) {
    byId.putIfAbsent(log.id, () => log);
  }
  if (byId.isEmpty) {
    return KidsWeeklyCoaching(
      status: KidsWeeklyCoachingStatus.noHistory,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  final week = <KidsSessionLog>[];
  final days = <DateTime>{};
  for (final log in byId.values) {
    final at = log.completedAt.toLocal();
    final day = DateTime(at.year, at.month, at.day);
    if (day.isBefore(periodStart) || day.isAfter(periodEnd)) continue;
    week.add(log);
    days.add(day);
  }

  final reviews = week
      .where(
        (l) =>
            l.missionType == KidsMissionType.dueReview ||
            l.missionType == KidsMissionType.linkedReview,
      )
      .length;
  final withHints = week.where((l) => l.hintCount > 0).length;
  final retried = week.where((l) => l.attemptCount > 1).length;
  final newAyahs = week
      .where((l) => l.missionType == KidsMissionType.newMemorization)
      .length;

  KidsWeeklyCoachingTip tip;
  if (week.isEmpty) {
    tip = KidsWeeklyCoachingTip.startSmall;
  } else if (week.length >= 2 && withHints * 2 >= week.length) {
    tip = KidsWeeklyCoachingTip.listenTogether;
  } else if (retried > 0) {
    tip = KidsWeeklyCoachingTip.celebrateEffort;
  } else if (days.length >= 4) {
    tip = KidsWeeklyCoachingTip.keepRhythm;
  } else if (newAyahs > 0 && reviews == 0) {
    tip = KidsWeeklyCoachingTip.addReview;
  } else {
    tip = KidsWeeklyCoachingTip.keepRhythm;
  }

  return KidsWeeklyCoaching(
    status: KidsWeeklyCoachingStatus.ready,
    periodStart: periodStart,
    periodEnd: periodEnd,
    sessions: week.length,
    activeDays: days.length,
    reviews: reviews,
    sessionsWithHints: withHints,
    retriedSessions: retried,
    tip: tip,
  );
}
