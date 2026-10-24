import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/parent_dashboard.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/guardian_milestone_detector.dart';

KidsSessionLog _log(
  String id,
  int surahId,
  int ayah,
  DateTime at, {
  int points = 5,
}) => KidsSessionLog(
  id: id,
  surahId: surahId,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: points,
  completedAt: at,
);

CertificateAward _cert(String id, DateTime at) => CertificateAward(
  id: id,
  titleAr: 'عنوان $id',
  type: CertificateType.surah,
  earnedAt: at,
);

// Wednesday 2026-10-14: the last full week is Mon 2026-10-05 .. Sun 10-11.
final _now = DateTime.utc(2026, 10, 14, 10);

List<GuardianMilestone> _detect({
  List<KidsSessionLog> logs = const [],
  Map<int, int> counts = const {},
  List<CertificateAward> certs = const [],
  int goal = 3,
}) => detectGuardianMilestones(
  logs: logs,
  ayahCountBySurah: counts,
  certificates: certs,
  weeklyGoalSessions: goal,
  now: _now,
);

void main() {
  test('nothing without data', () {
    expect(_detect(), isEmpty);
  });

  test('a surah with every ayah logged is a milestone with a stable id', () {
    final logs = [
      _log('a', 114, 1, DateTime.utc(2026, 10, 14)),
      _log('b', 114, 2, DateTime.utc(2026, 10, 14)),
      _log('c', 113, 1, DateTime.utc(2026, 10, 14)),
    ];
    final found = _detect(logs: logs, counts: {114: 2, 113: 5}, goal: 99);

    expect(found, [const SurahCompletedMilestone(114)]);
    expect(found.single.id, 'surah:114');
  });

  test('a certificate is a milestone; newest first, repeated ids once', () {
    final found = _detect(
      certs: [
        _cert('cert_surah_1', DateTime.utc(2026, 9, 1)),
        _cert('cert_surah_2', DateTime.utc(2026, 10, 1)),
        _cert('cert_surah_2', DateTime.utc(2026, 10, 1)),
      ],
    );

    expect(found.map((m) => m.id), ['cert:cert_surah_2', 'cert:cert_surah_1']);
    final first = found.first as CertificateEarnedMilestone;
    expect(first.titleAr, 'عنوان cert_surah_2');
  });

  test('meeting the goal in the last full week is a week milestone', () {
    final logs = [
      for (var i = 0; i < 3; i++)
        _log('w$i', 114, i + 1, DateTime.utc(2026, 10, 6 + i)),
    ];
    final found = _detect(logs: logs);

    expect(found.single, isA<WeekCompletedMilestone>());
    expect(found.single.id, 'week:2026-10-05');
  });

  test('the current week and a missed goal give no week milestone', () {
    final thisWeek = [
      for (var i = 0; i < 5; i++)
        _log('t$i', 114, i + 1, DateTime.utc(2026, 10, 12, i)),
    ];
    expect(_detect(logs: thisWeek), isEmpty);

    final twoLastWeek = [
      _log('x', 114, 1, DateTime.utc(2026, 10, 6)),
      _log('y', 114, 2, DateTime.utc(2026, 10, 7)),
    ];
    expect(_detect(logs: twoLastWeek), isEmpty);
  });

  test('the boundary: Sunday night counts, the next Monday does not', () {
    final logs = [
      _log('a', 114, 1, DateTime.utc(2026, 10, 5)),
      _log('b', 114, 2, DateTime.utc(2026, 10, 11, 23, 59)),
      _log('c', 114, 3, DateTime.utc(2026, 10, 12)),
    ];
    expect(_detect(logs: logs), isEmpty);
    expect(_detect(logs: logs, goal: 2).single.id, 'week:2026-10-05');
  });

  test('a promise whose surah is complete is due once, until claimed', () {
    ParentReward gift(String id, ParentRewardStatus status, {int? surah}) =>
        ParentReward(
          id: id,
          title: 'نزهة $id',
          status: status,
          createdAt: DateTime.utc(2026, 10, 1),
          milestoneSurahId: surah,
        );
    final milestones = detectGuardianMilestones(
      logs: [
        _log('a', 114, 1, DateTime.utc(2026, 10, 14)),
        _log('b', 114, 2, DateTime.utc(2026, 10, 14)),
      ],
      ayahCountBySurah: const {114: 2, 113: 5},
      certificates: const [],
      weeklyGoalSessions: 0,
      now: _now,
      rewards: [
        gift('due', ParentRewardStatus.locked, surah: 114),
        gift('due', ParentRewardStatus.locked, surah: 114),
        gift('asked', ParentRewardStatus.requested, surah: 114),
        gift('kept', ParentRewardStatus.claimed, surah: 114),
        gift('later', ParentRewardStatus.locked, surah: 113),
        gift('plain', ParentRewardStatus.locked),
      ],
    );
    expect(
      milestones.whereType<PromiseMetMilestone>().map((m) => m.id),
      ['promise:due', 'promise:asked'],
    );
    expect(milestones.first, const SurahCompletedMilestone(114));
  });
}
