import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_progress.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/remote_child_activity.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/remote_child_summary.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_achievements.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_progress_snapshot.dart';

void main() {
  final now = DateTime.utc(2026, 10, 8, 9);
  const progress = KidsProgress(
    totalPoints: 90,
    currentLevel: 2,
    currentStreak: 2,
    starsEarned: 4,
    ayahsCompleted: 11,
    lastSessionAt: null,
  );

  RemoteChildSummary summary({RemoteChildActivity? activity}) =>
      RemoteChildSummary(
        childUserId: 'child-1',
        displayName: 'مريم',
        progress: progress,
        logs: const [],
        rewards: const [],
        production: RemoteChildProductionSummary(
          totalMemorizedAyahs: 11,
          totalAyahsTracked: 11,
          completionPercent: 0,
          reviewsCompleted: 0,
          reviewsOverdue: 0,
          dailyPlanTotal: 0,
          dailyPlanCompleted: 0,
          activeDaysLast30: 0,
          certificates: [
            RemoteCertificateAward(
              certId: 'cert_surah_114',
              titleAr: 'شهادة حفظ سورة الناس',
              certType: 'surah',
              earnedAt: DateTime.utc(2026, 10, 1),
            ),
          ],
        ),
        activity: activity,
      );

  test('builds the child snapshot from the dashboard data', () {
    final snapshot = remoteKidsProgressSnapshot(
      summary(
        activity: RemoteChildActivity(
          updatedAt: now,
          dayKey: '2026-10-08',
          currentStreak: 2,
          longestStreak: 6,
          activeDaysLast30: 5,
          totalXp: 0,
          readPagesCount: 12,
          todayActivityCount: 1,
          todayReadPagesCount: 1,
          weekReadPagesCount: 4,
          achievements: {'streak7': DateTime.utc(2026, 9, 20)},
          events: [
            for (var i = 0; i < 7; i++)
              ActivityEvent(
                occurredAt: now.subtract(Duration(hours: i)),
                kind: ActivityEventKind.reading,
                idempotencyKey: 'reading|kids|$i',
                pageNumber: i + 1,
                isKids: true,
              ),
          ],
        ),
      ),
      now: now,
    );

    expect(snapshot.level, 2);
    expect(snapshot.memorizedAyahs, 11);
    expect(snapshot.weekPages, 4);
    expect(snapshot.longestStreak, 6);
    expect(snapshot.recentActivity, hasLength(5));

    final cert = snapshot.certificates.single;
    expect(cert.type, CertificateType.surah);
    expect(cert.surahId, 114);
    expect(cert.surahNameAr, isNotEmpty);

    KidsAchievement find(KidsAchievementId id) =>
        snapshot.achievements.singleWhere((a) => a.id == id);
    expect(find(KidsAchievementId.ayahs10).isUnlocked, isTrue);
    expect(find(KidsAchievementId.firstSurah).isUnlocked, isTrue);
    expect(find(KidsAchievementId.pages10).isUnlocked, isTrue);
    // Reached on the child device, kept even though 6 < 7 here.
    expect(
      find(KidsAchievementId.streak7).unlockedAt,
      DateTime.utc(2026, 9, 20),
    );
  });

  test('without a published activity, reading is unknown', () {
    final snapshot = remoteKidsProgressSnapshot(summary(), now: now);

    expect(snapshot.weekPages, isNull);
    expect(snapshot.recentActivity, isEmpty);
    expect(snapshot.longestStreak, 2);
  });
}
