import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_passage_picker.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

/// N4: a due review used to open one session per ayah, out of its context.
/// The passage keeps neighbouring due ayahs together, as a hafiz reviews.
void main() {
  List<Ayah> surah(int count, {int Function(int ayah)? pageOf}) => [
    for (var i = 1; i <= count; i++)
      Ayah(
        number: i,
        surahId: 67,
        text: 'a$i',
        numberInSurah: i,
        page: pageOf?.call(i),
      ),
  ];

  List<int> pick(
    List<Ayah> ayahs,
    int start,
    Set<int> due, {
    int maxAyahs = ReviewPassagePicker.defaultMaxAyahs,
  }) => ReviewPassagePicker.pick(
    surahAyahs: ayahs,
    startAyah: start,
    dueAyahNumbers: due,
    maxAyahs: maxAyahs,
  ).map((a) => a.numberInSurah).toList();

  test('extends over the contiguous due ayahs after the start', () {
    expect(pick(surah(10), 3, {3, 4, 5, 7}), [3, 4, 5]);
  });

  test('always keeps the requested ayah, even when not due', () {
    expect(pick(surah(10), 2, {5}), [2]);
  });

  test('stops at the end of the Mushaf page', () {
    final ayahs = surah(10, pageOf: (a) => a <= 4 ? 562 : 563);
    expect(pick(ayahs, 3, {3, 4, 5, 6}), [3, 4]);
  });

  test('is capped so one sitting stays short', () {
    expect(pick(surah(30), 1, {for (var i = 1; i <= 30; i++) i}, maxAyahs: 5), [
      1,
      2,
      3,
      4,
      5,
    ]);
  });

  test('an unknown start ayah yields nothing', () {
    expect(pick(surah(5), 9, {9}), isEmpty);
  });
}
