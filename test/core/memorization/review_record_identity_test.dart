import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';

void main() {
  group('ReviewRecordIdentity', () {
    const adult = ReviewRecordIdentity(
      ownerUserId: 'ab3f9c1e-0000-4aaa-8bbb-1c2d3e4f5a6b',
      audience: ReviewRecordReadScope.adult,
      surahId: 67,
      ayahNumber: 3,
    );

    test('storageKey uses pipe-separated owner, audience, surah, ayah', () {
      expect(
        adult.storageKey,
        'ab3f9c1e-0000-4aaa-8bbb-1c2d3e4f5a6b|adult|67|3',
      );
    });

    test('kids audience produces a distinct key for the same ayah', () {
      const kids = ReviewRecordIdentity(
        ownerUserId: 'ab3f9c1e-0000-4aaa-8bbb-1c2d3e4f5a6b',
        audience: ReviewRecordReadScope.kids,
        surahId: 67,
        ayahNumber: 3,
      );
      expect(kids.storageKey, isNot(adult.storageKey));
    });

    test('tryParse round-trips an identity key', () {
      expect(ReviewRecordIdentity.tryParse(adult.storageKey), adult);
    });

    test('tryParse returns null for the two legacy key generations', () {
      expect(ReviewRecordIdentity.tryParse('67_3'), isNull);
      expect(ReviewRecordIdentity.tryParse('adult_67_3'), isNull);
    });

    test('tryParse returns null for malformed keys', () {
      expect(ReviewRecordIdentity.tryParse('user|adult|67'), isNull);
      expect(ReviewRecordIdentity.tryParse('user|grownup|67|3'), isNull);
      expect(ReviewRecordIdentity.tryParse('user|adult|x|3'), isNull);
      expect(ReviewRecordIdentity.tryParse(''), isNull);
    });

    test('generationOf classifies all three key generations', () {
      expect(
        ReviewRecordIdentity.generationOf('67_3'),
        ReviewRecordKeyGeneration.legacy,
      );
      expect(
        ReviewRecordIdentity.generationOf('adult_67_3'),
        ReviewRecordKeyGeneration.audienceScoped,
      );
      expect(
        ReviewRecordIdentity.generationOf('kids_67_3'),
        ReviewRecordKeyGeneration.audienceScoped,
      );
      expect(
        ReviewRecordIdentity.generationOf(adult.storageKey),
        ReviewRecordKeyGeneration.identity,
      );
    });

    test('local owner is not syncable and a real owner is', () {
      const localOwned = ReviewRecordIdentity(
        ownerUserId: ReviewRecordIdentity.localOwnerId,
        audience: ReviewRecordReadScope.adult,
        surahId: 1,
        ayahNumber: 1,
      );
      expect(localOwned.isSyncable, isFalse);
      expect(adult.isSyncable, isTrue);
    });
  });
}
