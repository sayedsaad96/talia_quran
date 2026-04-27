import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer', () {
    test('removes tashkeel (diacritics) correctly', () {
      expect(
        ArabicNormalizer.normalize('بِسْمِ اللَّهِ'),
        equals('بسم الله'),
      );
    });

    test('removes full tashkeel from Quranic text', () {
      expect(
        ArabicNormalizer.normalize('الرَّحْمَٰنِ الرَّحِيمِ'),
        equals('الرحمن الرحيم'),
      );
    });

    test('normalizes alef variations', () {
      // All alef forms should normalize to bare alef
      expect(
        ArabicNormalizer.normalize('أحمد'),
        equals(ArabicNormalizer.normalize('احمد')),
      );
      expect(
        ArabicNormalizer.normalize('إبراهيم'),
        equals(ArabicNormalizer.normalize('ابراهيم')),
      );
      expect(
        ArabicNormalizer.normalize('آية'),
        equals(ArabicNormalizer.normalize('ايه')),
      );
    });

    test('normalizes hamza on carriers', () {
      // Hamza on waw
      expect(
        ArabicNormalizer.normalize('مؤمن'),
        equals('مومن'),
      );
      // Hamza on ya
      expect(
        ArabicNormalizer.normalize('بئر'),
        equals('بير'),
      );
    });

    test('normalizes ta marbuta to ha', () {
      expect(
        ArabicNormalizer.normalize('رحمة'),
        equals('رحمه'),
      );
    });

    test('normalizes ya and alif maksura', () {
      // Both should map to ya
      expect(
        ArabicNormalizer.normalize('على'),
        equals(ArabicNormalizer.normalize('علي')),
      );
    });

    test('removes tatweel (kashida)', () {
      expect(
        ArabicNormalizer.normalize('اللـــه'),
        equals('الله'),
      );
    });

    test('handles empty string', () {
      expect(ArabicNormalizer.normalize(''), equals(''));
    });

    test('trims and collapses whitespace', () {
      expect(
        ArabicNormalizer.normalize('  بسم   الله  '),
        equals('بسم الله'),
      );
    });

    test('handles punctuation removal', () {
      expect(
        ArabicNormalizer.normalize('قال؟ نعم!'),
        equals('قال نعم'),
      );
    });
  });
}
