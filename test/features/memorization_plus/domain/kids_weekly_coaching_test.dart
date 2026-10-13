import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_weekly_coaching.dart';

KidsSessionLog _log(
  String id,
  DateTime at, {
  KidsMissionType type = KidsMissionType.newMemorization,
  int hints = 0,
  int attempts = 1,
}) => KidsSessionLog(
  id: id,
  surahId: 1,
  ayahNumber: 1,
  repeatsCompleted: 1,
  pointsEarned: 0,
  completedAt: at,
  missionType: type,
  hintCount: hints,
  attemptCount: attempts,
);

void main() {
  // Local, non-UTC times so the calendar-day arithmetic matches the device.
  final now = DateTime(2026, 10, 8, 0, 5);

  KidsWeeklyCoaching build(
    List<KidsSessionLog> logs, {
    bool complete = true,
    DateTime? at,
  }) => buildKidsWeeklyCoaching(
    logs: logs,
    now: at ?? now,
    historyComplete: complete,
  );

  group('window', () {
    test('is seven local calendar days ending today', () {
      final c = build(const []);

      expect(c.periodStart, DateTime(2026, 10, 2));
      expect(c.periodEnd, DateTime(2026, 10, 8));
    });

    test('keeps the first and last minute of the window, drops the rest', () {
      final c = build([
        _log('before', DateTime(2026, 10, 1, 23, 59)),
        _log('first', DateTime(2026, 10, 2, 0, 0)),
        _log('today', DateTime(2026, 10, 8, 0, 1)),
        _log('later', DateTime(2026, 10, 9, 0, 0)),
      ]);

      expect(c.sessions, 2);
      expect(c.activeDays, 2);
    });

    test('shortly after midnight the previous day is still the last day', () {
      final c = build([
        _log('late', DateTime(2026, 10, 7, 23, 58)),
      ], at: DateTime(2026, 10, 8, 0, 2));

      expect(c.sessions, 1);
      expect(c.activeDays, 1);
    });

    test('a log repeated by a retry or merge counts once', () {
      final c = build([
        _log('a', DateTime(2026, 10, 7, 9)),
        _log('a', DateTime(2026, 10, 7, 9)),
      ]);

      expect(c.sessions, 1);
    });
  });

  group('status', () {
    test('an incomplete history concludes nothing', () {
      final c = build([_log('a', DateTime(2026, 10, 7, 9))], complete: false);

      expect(c.status, KidsWeeklyCoachingStatus.incompleteHistory);
      expect(c.sessions, 0);
      expect(c.tip, isNull);
    });

    test('no sessions ever is not a quiet week', () {
      final c = build(const []);

      expect(c.status, KidsWeeklyCoachingStatus.noHistory);
      expect(c.tip, isNull);
    });

    test('older sessions only is a quiet week with a gentle start', () {
      final c = build([_log('old', DateTime(2026, 9, 1, 9))]);

      expect(c.status, KidsWeeklyCoachingStatus.ready);
      expect(c.sessions, 0);
      expect(c.tip, KidsWeeklyCoachingTip.startSmall);
    });
  });

  group('tip', () {
    test('hints in at least half of two or more sessions: listen together', () {
      final c = build([
        _log('a', DateTime(2026, 10, 6, 9), hints: 1),
        _log('b', DateTime(2026, 10, 7, 9)),
      ]);

      expect(c.sessionsWithHints, 1);
      expect(c.tip, KidsWeeklyCoachingTip.listenTogether);
    });

    test('one session with a hint is not enough to advise listening', () {
      final c = build([_log('a', DateTime(2026, 10, 7, 9), hints: 2)]);

      expect(c.tip, isNot(KidsWeeklyCoachingTip.listenTogether));
    });

    test('a retry that succeeded is celebrated', () {
      final c = build([_log('a', DateTime(2026, 10, 7, 9), attempts: 3)]);

      expect(c.retriedSessions, 1);
      expect(c.tip, KidsWeeklyCoachingTip.celebrateEffort);
    });

    test('four active days keep the rhythm', () {
      final c = build([
        for (var d = 4; d <= 7; d++) _log('d$d', DateTime(2026, 10, d, 9)),
      ]);

      expect(c.activeDays, 4);
      expect(c.tip, KidsWeeklyCoachingTip.keepRhythm);
    });

    test('new ayahs without any review suggest adding one', () {
      final c = build([_log('a', DateTime(2026, 10, 7, 9))]);

      expect(c.reviews, 0);
      expect(c.tip, KidsWeeklyCoachingTip.addReview);
    });

    test('reviews are counted from due and linked sessions', () {
      final c = build([
        _log('a', DateTime(2026, 10, 7, 9), type: KidsMissionType.dueReview),
        _log(
          'b',
          DateTime(2026, 10, 7, 10),
          type: KidsMissionType.linkedReview,
        ),
      ]);

      expect(c.reviews, 2);
      expect(c.tip, KidsWeeklyCoachingTip.keepRhythm);
    });
  });
}
