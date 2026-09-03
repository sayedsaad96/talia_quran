import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';

void main() {
  KhatmahReadingResult completion(KhatmahPlan plan) => KhatmahReadingResult(
    plan: plan,
    newlyCompletedPages: const {604},
    historyEntry: KhatmahHistoryEntry(
      id: plan.id,
      khatmahNumber: 1,
      title: plan.title,
      startDate: plan.startDate,
      completedDate: DateTime(2026, 3, 5),
      totalDays: 5,
    ),
  );
  group('SocialShareCategory.khatmah', () {
    test('contains khatmah enum value', () {
      expect(SocialShareCategory.values, contains(SocialShareCategory.khatmah));
    });

    test('returns auto_stories_rounded icon', () {
      expect(SocialShareCategory.khatmah.icon, Icons.auto_stories_rounded);
    });

    test('supports Arabic & English titles / labels', () {
      expect(SocialShareCategory.khatmah.titleAr, contains('ختمة'));
      expect(SocialShareCategory.khatmah.titleEn, contains('Khatmah'));
      expect(
        SocialShareCategory.khatmah.labelAr,
        SocialShareCategory.khatmah.titleAr,
      );
      expect(
        SocialShareCategory.khatmah.labelEn,
        SocialShareCategory.khatmah.titleEn,
      );
    });
  });

  group('SocialShareData.khatmah factory', () {
    final basePlan = KhatmahPlan(
      id: 'khatmah-1',
      title: 'ختمة رمضان',
      startPage: 1,
      completedPages: {for (var page = 1; page <= 604; page++) page},
      targetPagesPerDay: 20,
      targetDays: 30,
      startDate: DateTime(2026, 3, 1),
      lastReadDate: DateTime(2026, 3, 5),
      expectedEndDate: DateTime(2026, 3, 30),
      status: KhatmahStatus.completed,
    );

    test('constructs share payload without dedication', () {
      final data = SocialShareData.khatmah(
        completion: completion(basePlan),
        userName: 'أحمد',
      );

      expect(data.category, SocialShareCategory.khatmah);
      expect(data.title, 'ختمة رمضان');
      expect(data.content, contains('5'));
      expect(data.targetValue, 5);
      expect(data.userName, 'أحمد');
      expect(data.subtitle, isNull);

      final shareText = data.toPlainShareText();
      expect(shareText, contains('ختمة رمضان'));
      expect(shareText, contains(SocialShareData.landingPageUrl));
      expect(shareText, isNot(contains('إهداء')));
    });

    test('rejects completion sharing without matching persisted history', () {
      expect(
        () => SocialShareData.khatmah(
          completion: KhatmahReadingResult(
            plan: basePlan,
            newlyCompletedPages: const {},
          ),
        ),
        throwsA(isA<KhatmahProgressException>()),
      );
      expect(
        () => SocialShareData.khatmah(
          completion: completion(basePlan.copyWith(completedPages: {604})),
        ),
        throwsA(isA<KhatmahProgressException>()),
      );
    });

    test('constructs share payload with dedication mention', () {
      final dedicatedPlan = basePlan.copyWith(
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'والدي الحبيب رحمه الله',
          relationship: 'والد',
          condition: DedicationCondition.deceased,
        ),
      );

      final data = SocialShareData.khatmah(
        completion: completion(dedicatedPlan),
        userName: 'أحمد',
      );

      expect(data.category, SocialShareCategory.khatmah);
      expect(data.subtitle, contains('والدي الحبيب'));
      expect(data.subtitle, contains('إهداء'));

      final shareText = data.toPlainShareText();
      expect(shareText, contains('إهداء'));
      expect(shareText, contains('والدي الحبيب'));
    });

    test('supports fallback title when plan title is empty', () {
      final emptyTitlePlan = basePlan.copyWith(title: '');
      final data = SocialShareData.khatmah(
        completion: completion(emptyTitlePlan),
      );

      expect(data.title, isNotEmpty);
      expect(data.title, contains('ختمة'));
    });
  });
}
