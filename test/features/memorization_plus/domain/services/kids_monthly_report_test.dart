import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_monthly_report.dart';

void main() {
  final now = DateTime(2026, 10, 30, 12);

  var seq = 0;
  KidsSessionLog log({
    required DateTime at,
    int surah = 112,
    int ayah = 1,
    List<int> ayahs = const [],
    KidsMissionType type = KidsMissionType.newMemorization,
    int points = 10,
    int attempts = 1,
    int hints = 0,
    PerformanceRating rating = PerformanceRating.excellent,
  }) => KidsSessionLog(
    id: 'l${seq++}',
    surahId: surah,
    ayahNumber: ayah,
    ayahNumbers: ayahs,
    repeatsCompleted: 3,
    pointsEarned: points,
    completedAt: at,
    missionType: type,
    attemptCount: attempts,
    hintCount: hints,
    masteryRating: rating,
  );

  KidsMonthlyReport build(List<KidsSessionLog> logs) => buildKidsMonthlyReport(
    logs: logs,
    ayahCountBySurah: const {112: 4, 113: 5},
    now: now,
  );

  test('the window is the last 30 local days, today included', () {
    final r = build([
      log(at: DateTime(2026, 10, 1, 0, 5)), // first day (30th back)
      log(at: DateTime(2026, 9, 30, 23, 59), ayah: 2), // just outside
      log(at: DateTime(2026, 10, 30, 23, 0), ayah: 3), // today
      log(at: DateTime(2026, 10, 31, 1), ayah: 4), // future, outside
    ]);
    expect(r.periodStart, DateTime(2026, 10, 1));
    expect(r.periodEnd, DateTime(2026, 10, 30));
    expect(r.sessions, 2);
    expect(r.activeDays, 2);
    expect(r.newAyahs, 2);
  });

  test('counts reviews and hint sessions like the weekly summary', () {
    final r = build([
      log(at: DateTime(2026, 10, 20), type: KidsMissionType.dueReview),
      log(at: DateTime(2026, 10, 21), type: KidsMissionType.linkedReview),
      log(at: DateTime(2026, 10, 21), hints: 2),
    ]);
    expect(r.sessions, 3);
    expect(r.reviews, 2);
    expect(r.sessionsWithHints, 1);
    expect(r.newAyahs, 1);
  });

  test('duplicate log ids count once', () {
    final one = log(at: DateTime(2026, 10, 20));
    final r = build([one, one]);
    expect(r.sessions, 1);
  });

  test('a surah counts only when it became complete inside the period', () {
    final r = build([
      // 112 completed in September, then revisited in October.
      log(at: DateTime(2026, 9, 10), surah: 112, ayah: 1, ayahs: [1, 2]),
      log(at: DateTime(2026, 9, 11), surah: 112, ayah: 3, ayahs: [3, 4]),
      log(at: DateTime(2026, 10, 20), surah: 112, ayah: 1),
      // 113 completed inside the period.
      log(at: DateTime(2026, 10, 5), surah: 113, ayah: 1, ayahs: [1, 2, 3]),
      log(at: DateTime(2026, 10, 6), surah: 113, ayah: 4, ayahs: [4, 5]),
    ]);
    expect(r.completedSurahIds, [113]);
  });

  test('an incomplete surah is not completed', () {
    final r = build([
      log(at: DateTime(2026, 10, 5), surah: 113, ayah: 1, ayahs: [1, 2]),
    ]);
    expect(r.completedSurahIds, isEmpty);
  });

  test('needsSupport needs two failures or weak ratings, newest first', () {
    final r = build([
      // ayah 1: 2 extra attempts -> 2 failures, last Oct 10.
      log(at: DateTime(2026, 10, 10), ayah: 1, attempts: 3),
      // ayah 2: two weak ratings, last Oct 15.
      log(at: DateTime(2026, 10, 14), ayah: 2, rating: PerformanceRating.weak),
      log(at: DateTime(2026, 10, 15), ayah: 2, rating: PerformanceRating.weak),
      // ayah 3: a single failure only.
      log(at: DateTime(2026, 10, 16), ayah: 3, attempts: 2),
    ]);
    expect(r.needsSupport, [
      (surahId: 112, ayahNumber: 2),
      (surahId: 112, ayahNumber: 1),
    ]);
  });

  test('needsSupport ignores failures outside the period', () {
    final r = build([
      log(at: DateTime(2026, 9, 1), ayah: 1, attempts: 4),
      log(at: DateTime(2026, 10, 10), ayah: 1, attempts: 2),
    ]);
    expect(r.needsSupport, isEmpty);
  });

  test('needsSupport is capped at ten', () {
    final r = build([
      for (var a = 1; a <= 12; a++)
        log(at: DateTime(2026, 10, a), surah: 2, ayah: a, attempts: 3),
    ]);
    expect(r.needsSupport, hasLength(10));
    expect(r.needsSupport.first, (surahId: 2, ayahNumber: 12));
    expect(r.needsSupport.last, (surahId: 2, ayahNumber: 3));
  });

  test('no sessions in the period is empty', () {
    expect(build(const []).isEmpty, isTrue);
    expect(build([log(at: DateTime(2026, 8, 1))]).isEmpty, isTrue);
    expect(build([log(at: DateTime(2026, 10, 2))]).isEmpty, isFalse);
  });
}
