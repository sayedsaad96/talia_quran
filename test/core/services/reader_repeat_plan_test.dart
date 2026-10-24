import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/reader_repeat_plan.dart';

void main() {
  test('perAyah 3, rangeTimes 2 over [a,b] expands in order', () {
    final r = expandRepeatQueue([
      'a',
      'b',
    ], const ReaderRepeatSettings(perAyah: 3, rangeTimes: 2));
    expect(r, ['a', 'a', 'a', 'b', 'b', 'b', 'a', 'a', 'a', 'b', 'b', 'b']);
  });

  test('defaults return the input unchanged', () {
    expect(expandRepeatQueue(['a', 'b'], const ReaderRepeatSettings()), [
      'a',
      'b',
    ]);
    expect(const ReaderRepeatSettings().isDefault, isTrue);
    expect(const ReaderRepeatSettings(perAyah: 2).isDefault, isFalse);
  });

  test('rangeTimes 0 yields a single pass', () {
    expect(
      expandRepeatQueue([
        'a',
        'b',
      ], const ReaderRepeatSettings(perAyah: 2, rangeTimes: 0)),
      ['a', 'a', 'b', 'b'],
    );
  });

  test('clamping: perAyah 0 to 1, 11 to 10', () {
    expect(expandRepeatQueue(['a'], const ReaderRepeatSettings(perAyah: 0)), [
      'a',
    ]);
    expect(
      expandRepeatQueue(['a'], const ReaderRepeatSettings(perAyah: 11)).length,
      10,
    );
    expect(
      expandRepeatQueue([
        'a',
      ], const ReaderRepeatSettings(rangeTimes: 11)).length,
      10,
    );
  });

  test('speed snaps to allowed values', () {
    expect(const ReaderRepeatSettings(speed: 1.1).normalizedSpeed, 1.0);
    expect(const ReaderRepeatSettings(speed: 0.75).normalizedSpeed, 0.75);
    expect(const ReaderRepeatSettings(speed: 1.5).normalizedSpeed, 1.5);
  });

  test('nextDistinctIndex skips repeats; null at the end', () {
    final q = ['a', 'a', 'a', 'b', 'b'];
    expect(nextDistinctIndex(q, 0), 3);
    expect(nextDistinctIndex(q, 2), 3);
    expect(nextDistinctIndex(q, 3), isNull);
    expect(nextDistinctIndex(q, 4), isNull);
  });

  test('previousDistinctIndex returns first index of previous run', () {
    final q = ['a', 'a', 'b', 'b', 'c'];
    expect(previousDistinctIndex(q, 4), 2);
    expect(previousDistinctIndex(q, 3), 0);
    expect(previousDistinctIndex(q, 2), 0);
    expect(previousDistinctIndex(q, 1), isNull);
    expect(previousDistinctIndex(q, 0), isNull);
  });

  test('wrapped queue: next and previous cross range passes', () {
    final q = ['a', 'a', 'b', 'b', 'a', 'a', 'b', 'b'];
    expect(nextDistinctIndex(q, 3), 4);
    expect(previousDistinctIndex(q, 4), 2);
  });

  test('custom same predicate is honoured', () {
    final q = ['a', 'A', 'b'];
    expect(
      nextDistinctIndex(
        q,
        0,
        same: (x, y) => x.toLowerCase() == y.toLowerCase(),
      ),
      2,
    );
  });

  test('firstPassIndexOf and passEndIndexOf follow the expanded queue', () {
    const s = ReaderRepeatSettings(perAyah: 2, rangeTimes: 3);
    final q = expandRepeatQueue(['a', 'b', 'c'], s);
    expect(q[firstPassIndexOf(1, s)], 'b');
    expect(firstPassIndexOf(1, s), q.indexOf('b'));
    expect(passEndIndexOf(0, 3, s), 5);
    expect(passEndIndexOf(7, 3, s), 11);
    expect(passEndIndexOf(4, 0, s), 4);
  });

  test('clampAyahRange clamps the end and rejects invalid ranges', () {
    expect(clampAyahRange(2, 4, 7), (start: 2, end: 4));
    expect(clampAyahRange(3, 3, 7), (start: 3, end: 3));
    expect(clampAyahRange(5, 99, 7), (start: 5, end: 7));
    expect(clampAyahRange(0, 3, 7), isNull);
    expect(clampAyahRange(4, 3, 7), isNull);
    expect(clampAyahRange(8, 9, 7), isNull);
    expect(clampAyahRange(1, 1, 0), isNull);
  });
}
