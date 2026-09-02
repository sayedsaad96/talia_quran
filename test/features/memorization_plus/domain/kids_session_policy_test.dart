import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('KidsSessionPolicy', () {
    test('ages five to seven use one short non-blocking learning mission', () {
      final policy = KidsSessionPolicy.forAge(6);

      expect(policy.ageBand, KidsAgeBand.fiveToSeven);
      expect(policy.maxNewAyahs, 1);
      expect(policy.maxDueReviews, 1);
      expect(policy.maxSessionMinutes, 6);
      expect(policy.journeyStageSize, 3);
      expect(policy.blockReviewRequired, isFalse);
      expect(policy.guidanceAudioDefault, isTrue);
    });

    test('ages eight to twelve require linked review and a larger stage', () {
      final policy = KidsSessionPolicy.forAge(10);

      expect(policy.ageBand, KidsAgeBand.eightToTwelve);
      expect(policy.maxNewAyahs, 2);
      expect(policy.maxDueReviews, 3);
      expect(policy.maxSessionMinutes, 10);
      expect(policy.journeyStageSize, 5);
      expect(policy.blockReviewRequired, isTrue);
      expect(policy.linkedReviewAyahs, 3);
      expect(policy.guidanceAudioDefault, isFalse);
    });

    test('rejects ages outside the supported child path', () {
      expect(() => KidsSessionPolicy.forAge(4), throwsRangeError);
      expect(() => KidsSessionPolicy.forAge(13), throwsRangeError);
    });
  });

  test('kids journey starts from An-Nas and stops at An-Naba', () {
    expect(KidsJourneyCursor.initial.activeSurahId, 114);
    expect(KidsJourneyCursor.nextJuzAmmaSurah(114), 113);
    expect(KidsJourneyCursor.nextJuzAmmaSurah(78), isNull);
  });
}
