import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_dedupe.dart';

Zikr _zikr(String id, String text, {int count = 1}) => Zikr(
  id: id,
  text: text,
  transliteration: '',
  translation: '',
  totalCount: count,
  category: AzkarCategory.duas,
);

void main() {
  test('keeps the first record and lists later copies as aliases', () {
    final result = AzkarDedupe.apply([
      _zikr('a', 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'),
      _zikr('b', 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى'),
      _zikr('c', 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'),
    ]);

    expect(result.items.map((z) => z.id), ['a', 'b']);
    expect(result.aliases, {
      'a': {'c'},
    });
  });

  test('matches across diacritics and alef variants', () {
    final result = AzkarDedupe.apply([
      _zikr('a', 'رَبَّنَا آتِنَا'),
      _zikr('b', 'ربنا اتنا'),
    ]);

    expect(result.items.map((z) => z.id), ['a']);
    expect(result.aliases['a'], {'b'});
  });

  test('ignores the Arabic comma and full stops when comparing', () {
    final result = AzkarDedupe.apply([
      _zikr('a', 'الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ.'),
      _zikr('b', 'الْهَمِّ وَالْحَزَنِ وَالْعَجْزِ'),
    ]);

    expect(result.items.map((z) => z.id), ['a']);
    expect(result.aliases['a'], {'b'});
  });

  test('same text with a different count is not a duplicate', () {
    final result = AzkarDedupe.apply([
      _zikr('a', 'سُبْحَانَ اللَّهِ', count: 3),
      _zikr('b', 'سُبْحَانَ اللَّهِ', count: 33),
    ]);

    expect(result.items.map((z) => z.id), ['a', 'b']);
    expect(result.aliases, isEmpty);
  });

  test('a list without duplicates comes back unchanged', () {
    final input = [_zikr('a', 'نص أول'), _zikr('b', 'نص ثان')];

    final result = AzkarDedupe.apply(input);

    expect(result.items, input);
    expect(result.aliases, isEmpty);
  });

  test('an empty list yields an empty result', () {
    final result = AzkarDedupe.apply(const []);

    expect(result.items, isEmpty);
    expect(result.aliases, isEmpty);
  });
}
