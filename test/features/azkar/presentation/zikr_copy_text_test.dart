import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/presentation/services/zikr_copy_text.dart';

Zikr _zikr({String reference = ''}) => Zikr(
  id: 'z',
  text: 'نص الذكر',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.duas,
  reference: reference,
);

void main() {
  test('joins text, reference and footer with blank lines', () {
    expect(
      zikrCopyText(_zikr(reference: 'صحيح مسلم'), footer: 'من تطبيق تالية'),
      'نص الذكر\n\nصحيح مسلم\n\nمن تطبيق تالية',
    );
  });

  test('skips an empty reference', () {
    expect(
      zikrCopyText(_zikr(), footer: 'من تطبيق تالية'),
      'نص الذكر\n\nمن تطبيق تالية',
    );
  });

  test('never alters the stored text', () {
    const text = 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً';
    const zikr = Zikr(
      id: 'z',
      text: text,
      transliteration: '',
      translation: '',
      totalCount: 1,
      category: AzkarCategory.duas,
    );

    expect(zikrCopyText(zikr, footer: 'f').startsWith(text), isTrue);
  });
}
