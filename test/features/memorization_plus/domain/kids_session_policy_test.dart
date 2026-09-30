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
      expect(policy.guidanceAudioDefault, isTrue);
      // Pedagogically inverted: younger children need MORE listens, not
      // fewer — three conscious repetitions before recall.
      expect(policy.maxListenRepetitions, 3);
    });

    test('ages eight to twelve get a larger quota and stage', () {
      final policy = KidsSessionPolicy.forAge(10);

      expect(policy.ageBand, KidsAgeBand.eightToTwelve);
      expect(policy.maxNewAyahs, 2);
      expect(policy.maxDueReviews, 3);
      expect(policy.maxSessionMinutes, 10);
      expect(policy.journeyStageSize, 5);
      expect(policy.guidanceAudioDefault, isFalse);
      expect(policy.maxListenRepetitions, 2);
    });

    test('a missing or out-of-range stored age falls back to 8–12', () {
      expect(KidsSessionPolicy.forChildAge(null), KidsSessionPolicy.forAge(8));
      expect(KidsSessionPolicy.forChildAge(3), KidsSessionPolicy.forAge(8));
      expect(KidsSessionPolicy.forChildAge(15), KidsSessionPolicy.forAge(8));
      expect(KidsSessionPolicy.forChildAge(6), KidsSessionPolicy.forAge(6));
    });

    test('rejects ages outside the supported child path', () {
      expect(() => KidsSessionPolicy.forAge(4), throwsRangeError);
      expect(() => KidsSessionPolicy.forAge(13), throwsRangeError);
    });
  });

  test('kids journey opens with Al-Fatiha, then An-Nas to An-Naba (K27)', () {
    expect(KidsJourneyCursor.initial.activeSurahId, 1);
    expect(KidsJourneyPath.surahIds.first, 1);
    expect(KidsJourneyPath.surahIds[1], 114);
    expect(KidsJourneyPath.surahIds.last, 78);
    expect(KidsJourneyPath.surahIds, hasLength(38));

    expect(KidsJourneyPath.nextAfter(1), 114);
    expect(KidsJourneyPath.nextAfter(114), 113);
    expect(KidsJourneyPath.nextAfter(79), 78);
    expect(KidsJourneyPath.nextAfter(78), isNull);

    expect(KidsJourneyPath.contains(1), isTrue);
    expect(KidsJourneyPath.contains(78), isTrue);
    expect(KidsJourneyPath.contains(2), isFalse);
    expect(KidsJourneyPath.contains(77), isFalse);
  });
}
