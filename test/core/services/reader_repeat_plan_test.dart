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
}
