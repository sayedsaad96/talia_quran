import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_progress.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_progress_snapshot.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  final now = DateTime(2026, 10, 8, 9);
  CertificateAward cert(String id, CertificateType type, int day) =>
      CertificateAward(
        id: id,
        titleAr: id,
        type: type,
        earnedAt: DateTime.utc(2026, 10, day),
      );

  KidsAchievementInputs? seenInputs;

  KidsProgressSnapshotLoader loader({
    Map<String, Set<int>> pagesByDay = const {},
    List<CertificateAward> certificates = const [],
  }) => KidsProgressSnapshotLoader(
    progress: () async => const KidsProgress(
      totalPoints: 120,
      currentLevel: 2,
      currentStreak: 4,
      starsEarned: 6,
      ayahsCompleted: 14,
      lastSessionAt: null,
    ),
    streak: () async => const StreakEntity(currentStreak: 4, longestStreak: 9),
    pagesOn: (day) async => pagesByDay[day] ?? const {},
    allPages: () async => {for (final p in pagesByDay.values) ...p},
    certificates: () => certificates,
    recentActivity: () async => [
      ActivityEvent(
        occurredAt: now,
        kind: ActivityEventKind.reading,
        idempotencyKey: 'reading|kids|20261008|3',
        pageNumber: 3,
        isKids: true,
      ),
    ],
    achievements: (inputs) async {
      seenInputs = inputs;
      return KidsAchievementCatalog.evaluate(inputs, now: now.toUtc());
    },
    clock: () => now,
  );

  test('collects the kids-only numbers', () async {
    final snapshot = await loader(
      pagesByDay: {
        '2026-10-08': {3, 4},
        '2026-10-02': {4, 5},
        '2026-09-20': {50},
      },
      certificates: [
        cert('cert_surah_114', CertificateType.surah, 1),
        cert('cert_surah_113', CertificateType.surah, 3),
        cert('cert_juz_30', CertificateType.juz, 2),
      ],
    ).load();

    expect(snapshot.level, 2);
    expect(snapshot.stars, 6);
    expect(snapshot.currentStreak, 4);
    expect(snapshot.longestStreak, 9);
    expect(snapshot.memorizedAyahs, 14);
    // 3, 4 and 5 within the last 7 days; page 50 is older.
    expect(snapshot.weekPages, 3);
    expect(snapshot.recentActivity.single.pageNumber, 3);
    // Newest certificate first.
    expect(snapshot.certificates.map((c) => c.id), [
      'cert_surah_113',
      'cert_juz_30',
      'cert_surah_114',
    ]);
    expect(
      seenInputs,
      const KidsAchievementInputs(
        memorizedAyahs: 14,
        memorizedSurahs: 2,
        readPages: 4,
        longestStreak: 9,
        stars: 6,
      ),
    );
    expect(
      snapshot.achievements
          .singleWhere((a) => a.id == KidsAchievementId.ayahs10)
          .isUnlocked,
      isTrue,
    );
  });

  test('the longest streak is never below the current one', () async {
    final snapshot = await KidsProgressSnapshotLoader(
      progress: () async => const KidsProgress.initial(),
      streak: () async =>
          const StreakEntity(currentStreak: 5, longestStreak: 2),
      pagesOn: (_) async => const {},
      allPages: () async => const {},
      certificates: () => const [],
      recentActivity: () async => const [],
      achievements: (inputs) async =>
          KidsAchievementCatalog.evaluate(inputs, now: now),
      clock: () => now,
    ).load();

    expect(snapshot.longestStreak, 5);
  });
}
