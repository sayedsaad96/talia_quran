import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';

void main() {
  group('SocialShareCategory.khatmah', () {
    test('contains khatmah enum value', () {
      expect(SocialShareCategory.values, contains(SocialShareCategory.khatmah));
    });

    test('returns auto_stories_rounded icon', () {
      expect(
        SocialShareCategory.khatmah.icon,
        Icons.auto_stories_rounded,
      );
    });

    test('supports Arabic & English titles / labels', () {
      expect(SocialShareCategory.khatmah.titleAr, contains('ختمة'));
      expect(SocialShareCategory.khatmah.titleEn, contains('Khatmah'));
      expect(SocialShareCategory.khatmah.labelAr, SocialShareCategory.khatmah.titleAr);
      expect(SocialShareCategory.khatmah.labelEn, SocialShareCategory.khatmah.titleEn);
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
      expectedEndDate: DateTime(2026, 3, 30),
      status: KhatmahStatus.completed,
    );

    test('constructs share payload without dedication', () {
      final data = SocialShareData.khatmah(
        plan: basePlan,
        userName: 'أحمد',
      );

      expect(data.category, SocialShareCategory.khatmah);
      expect(data.title, 'ختمة رمضان');
      expect(data.content, contains('30'));
      expect(data.userName, 'أحمد');
      expect(data.subtitle, isNull);

      final shareText = data.toPlainShareText();
      expect(shareText, contains('ختمة رمضان'));
      expect(shareText, contains(SocialShareData.landingPageUrl));
      expect(shareText, isNot(contains('إهداء')));
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
        plan: dedicatedPlan,
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
      final data = SocialShareData.khatmah(plan: emptyTitlePlan);

      expect(data.title, isNotEmpty);
      expect(data.title, contains('ختمة'));
    });
  });
}
