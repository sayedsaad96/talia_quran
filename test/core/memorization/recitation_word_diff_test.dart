import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/memorization/v2/recitation_word_diff.dart';

void main() {
  const differ = RecitationWordDiffer();

  group('RecitationWordDiffer', () {
    test('perfect recitation marks every word as match', () {
      final result = differ.diff(
        targetText: 'الحمد لله رب العالمين',
        spokenText: 'الحمد لله رب العالمين',
      );

      expect(result.words, hasLength(4));
      expect(
        result.words.map((w) => w.status),
        everyElement(RecitationWordStatus.match),
      );
      expect(result.isPerfect, isTrue);
      expect(result.matchCount, 4);
    });

    test('normalization equivalence still matches (tashkeel, alef forms)', () {
      final result = differ.diff(
        targetText: 'إِنَّ اللَّهَ غَفُورٌ',
        spokenText: 'ان الله غفور',
      );

      expect(result.isPerfect, isTrue);
    });

    test('a substituted word is marked wrong in place', () {
      final result = differ.diff(
        targetText: 'الحمد لله رب العالمين',
        spokenText: 'الحمد لله ملك العالمين',
      );

      expect(result.words, hasLength(4));
      expect(result.words[2].status, RecitationWordStatus.wrong);
      // Wrong slots always display the target word.
      expect(result.words[2].display, 'رب');
      expect(result.matchCount, 3);
      expect(result.wrongCount, 1);
    });

    test('a skipped target word is marked missing', () {
      final result = differ.diff(
        targetText: 'الحمد لله رب العالمين',
        spokenText: 'الحمد لله العالمين',
      );

      expect(result.words, hasLength(4));
      final missing = result.words
          .where((w) => w.status == RecitationWordStatus.missing)
          .toList();
      expect(missing, hasLength(1));
      expect(missing.single.display, 'رب');
      expect(result.missingCount, 1);
    });

    test('an inserted spoken word is marked extra', () {
      final result = differ.diff(
        targetText: 'الحمد لله',
        spokenText: 'الحمد لله الكريم',
      );

      expect(result.extraCount, 1);
      expect(result.words.last.display, 'الكريم');
    });

    test('repeated words align in order without pairing the wrong instance', () {
      final result = differ.diff(
        targetText: 'قل هو الله أحد',
        spokenText: 'قل هو الله أحد الله',
      );

      expect(result.matchCount, 4);
      expect(result.extraCount, 1);
      expect(result.missingCount, 0);
      expect(result.wrongCount, 0);
    });

    test('missing alignment preserves render order around matches', () {
      final result = differ.diff(
        targetText: 'أ ب ج د',
        spokenText: 'أ ب د',
      );

      expect(
        result.words.map((w) => (w.display, w.status)),
        [
          ('أ', RecitationWordStatus.match),
          ('ب', RecitationWordStatus.match),
          ('ج', RecitationWordStatus.missing),
          ('د', RecitationWordStatus.match),
        ],
      );
    });

    test('empty spoken text renders the target as missing', () {
      final result = differ.diff(
        targetText: 'الحمد لله',
        spokenText: '',
      );

      expect(result.missingCount, 2);
      expect(result.matchCount, 0);
    });

    test('empty target renders spoken words as extra', () {
      final result = differ.diff(
        targetText: '',
        spokenText: 'الحمد لله',
      );

      expect(result.extraCount, 2);
    });

    test('both empty yields an empty diff', () {
      final result = differ.diff(targetText: '', spokenText: ' ');

      expect(result.words, isEmpty);
      expect(result.isPerfect, isTrue);
    });
  });
}
