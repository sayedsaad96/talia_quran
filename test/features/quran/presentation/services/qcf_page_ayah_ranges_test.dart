import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/services/qcf_page_ayah_ranges.dart';

void main() {
  test('page 1 maps to Al-Fatihah 1-7; invalid pages are empty', () {
    expect(qcfPageAyahRanges(1), [(surah: 1, start: 1, end: 7)]);
    expect(qcfPageAyahRanges(0), isEmpty);
    expect(qcfPageAyahRanges(605), isEmpty);
  });
}
