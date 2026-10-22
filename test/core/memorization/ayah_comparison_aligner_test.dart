import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/similar_ayah/ayah_comparison_aligner.dart';

void main() {
  const aligner = AyahComparisonAligner();

  group('AyahComparisonAligner', () {
    test(
      'preserves each original string and marks changed prefix and suffix',
      () {
        const left = 'old middle end';
        const right = 'new middle last';
        final alignment = aligner.align(leftText: left, rightText: right);

        _expectReconstruction(left, alignment.left);
        _expectReconstruction(right, alignment.right);
        expect(_wordStatuses(left, alignment.left), [
          AyahComparisonSpanStatus.different,
          AyahComparisonSpanStatus.match,
          AyahComparisonSpanStatus.different,
        ]);
        expect(_wordStatuses(right, alignment.right), [
          AyahComparisonSpanStatus.different,
          AyahComparisonSpanStatus.match,
          AyahComparisonSpanStatus.different,
        ]);
      },
    );

    test(
      'retains whitespace and standalone marks at their source positions',
      () {
        const text = '  alpha\t۞ beta  ';
        final alignment = aligner.align(leftText: text, rightText: text);

        _expectReconstruction(text, alignment.left);
        _expectReconstruction(text, alignment.right);
        expect(
          _textFor(text, alignment.left, AyahComparisonSpanStatus.nonrecitable),
          contains('\t۞ '),
        );
        expect(_wordStatuses(text, alignment.left), [
          AyahComparisonSpanStatus.match,
          AyahComparisonSpanStatus.match,
        ]);
      },
    );

    test('uses per-word normalization while retaining original code units', () {
      const left = 'أَب blue';
      const right = 'اب blue';
      final alignment = aligner.align(leftText: left, rightText: right);

      _expectReconstruction(left, alignment.left);
      _expectReconstruction(right, alignment.right);
      expect(
        _wordStatuses(left, alignment.left),
        everyElement(AyahComparisonSpanStatus.match),
      );
    });

    test(
      'does not use whole-string multi-word normalization for visual spans',
      () {
        const left = 'يا ايها';
        const right = 'ياايها';
        final alignment = aligner.align(leftText: left, rightText: right);

        _expectReconstruction(left, alignment.left);
        _expectReconstruction(right, alignment.right);
        expect(
          _wordStatuses(left, alignment.left),
          everyElement(AyahComparisonSpanStatus.different),
        );
        expect(
          _wordStatuses(right, alignment.right),
          everyElement(AyahComparisonSpanStatus.different),
        );
      },
    );

    test('marks an insertion only in the string that owns it', () {
      const left = 'first last';
      const right = 'first inserted last';
      final alignment = aligner.align(leftText: left, rightText: right);

      _expectReconstruction(left, alignment.left);
      _expectReconstruction(right, alignment.right);
      expect(
        _wordStatuses(left, alignment.left),
        everyElement(AyahComparisonSpanStatus.match),
      );
      expect(_wordStatuses(right, alignment.right), [
        AyahComparisonSpanStatus.match,
        AyahComparisonSpanStatus.different,
        AyahComparisonSpanStatus.match,
      ]);
    });

    test('chooses substitution before deletion or insertion on a tie', () {
      const left = 'alpha beta';
      const right = 'gamma beta';
      final alignment = aligner.align(leftText: left, rightText: right);

      expect(_wordStatuses(left, alignment.left), [
        AyahComparisonSpanStatus.different,
        AyahComparisonSpanStatus.match,
      ]);
      expect(_wordStatuses(right, alignment.right), [
        AyahComparisonSpanStatus.different,
        AyahComparisonSpanStatus.match,
      ]);
    });

    test('aligns repeated words deterministically', () {
      const left = 'red blue red';
      const right = 'red red';
      final first = aligner.align(leftText: left, rightText: right);
      final second = aligner.align(leftText: left, rightText: right);

      expect(_statusSignature(first.left), _statusSignature(second.left));
      expect(_statusSignature(first.right), _statusSignature(second.right));
      expect(_wordStatuses(left, first.left), [
        AyahComparisonSpanStatus.match,
        AyahComparisonSpanStatus.different,
        AyahComparisonSpanStatus.match,
      ]);
    });

    test(
      'returns immutable contiguous spans for empty and non-recitable text',
      () {
        final empty = aligner.align(leftText: '', rightText: ' ۩ ');

        expect(empty.left, isEmpty);
        _expectReconstruction(' ۩ ', empty.right);
        expect(
          empty.right.map((span) => span.status),
          everyElement(AyahComparisonSpanStatus.nonrecitable),
        );
        expect(
          () => empty.right.add(empty.right.first),
          throwsUnsupportedError,
        );
      },
    );
  });

  test('reconstructs both original sides for every canonical corpus ayah', () {
    final corpus =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;
    var count = 0;
    for (var surah = 1; surah <= 114; surah++) {
      for (final item in corpus['$surah'] as List<dynamic>) {
        final ayah = item as Map<String, dynamic>;
        expect(ayah['chapter'], surah);
        expect(ayah['verse'], isA<int>());
        expect(ayah['global'], isA<int>());
        expect(ayah['page'], isA<int>());
        expect(ayah['juz'], isA<int>());
        final text = ayah['text'] as String;
        final alignment = aligner.align(leftText: text, rightText: text);
        _expectReconstruction(text, alignment.left);
        _expectReconstruction(text, alignment.right);
        count++;
      }
    }
    expect(count, 6236);
  });
}

void _expectReconstruction(String source, List<AyahComparisonSpan> spans) {
  var cursor = 0;
  final buffer = StringBuffer();
  for (final span in spans) {
    expect(span.start, cursor);
    expect(span.end, greaterThan(span.start));
    expect(span.end, lessThanOrEqualTo(source.length));
    buffer.write(source.substring(span.start, span.end));
    cursor = span.end;
  }
  expect(cursor, source.length);
  expect(buffer.toString(), source);
}

List<AyahComparisonSpanStatus> _wordStatuses(
  String source,
  List<AyahComparisonSpan> spans,
) => [
  for (final span in spans)
    if (span.status != AyahComparisonSpanStatus.nonrecitable &&
        source.substring(span.start, span.end).trim().isNotEmpty)
      span.status,
];

String _textFor(
  String source,
  List<AyahComparisonSpan> spans,
  AyahComparisonSpanStatus status,
) => spans
    .where((span) => span.status == status)
    .map((span) => source.substring(span.start, span.end))
    .join();

List<(int, int, AyahComparisonSpanStatus)> _statusSignature(
  List<AyahComparisonSpan> spans,
) => [for (final span in spans) (span.start, span.end, span.status)];
