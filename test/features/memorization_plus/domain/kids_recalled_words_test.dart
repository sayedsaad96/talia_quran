import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_recalled_words.dart';

void main() {
  group('kidsRecalledWords (K32)', () {
    test('flags each ayah word in order and ignores extra spoken words', () {
      expect(
        kidsRecalledWords(targetText: 'a b c d', spokenText: 'a x c d extra'),
        [true, false, true, true],
      );
    });

    test('a skipped word stays unrecalled', () {
      expect(kidsRecalledWords(targetText: 'a b c', spokenText: 'a c'), [
        true,
        false,
        true,
      ]);
    });

    test('silence recalls nothing', () {
      expect(kidsRecalledWords(targetText: 'a b', spokenText: ''), [
        false,
        false,
      ]);
    });
  });
}
