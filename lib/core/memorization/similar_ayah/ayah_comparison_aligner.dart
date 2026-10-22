import '../../utils/arabic_normalizer.dart';
import '../v2/recitation_word_diff.dart';

/// The visual status of an exact substring in its original ayah text.
enum AyahComparisonSpanStatus { match, different, nonrecitable }

/// A half-open range into one original ayah string. It never holds text.
final class AyahComparisonSpan {
  const AyahComparisonSpan({
    required this.start,
    required this.end,
    required this.status,
  });

  final int start;
  final int end;
  final AyahComparisonSpanStatus status;
}

/// Exact-source spans for both sides of a comparison.
final class AyahComparisonAlignment {
  AyahComparisonAlignment({
    required List<AyahComparisonSpan> left,
    required List<AyahComparisonSpan> right,
  }) : left = List.unmodifiable(left),
       right = List.unmodifiable(right);

  final List<AyahComparisonSpan> left;
  final List<AyahComparisonSpan> right;
}

/// Aligns original ayah strings without introducing, replacing, or moving text.
///
/// This is a rendering contract rather than recitation scoring: it normalizes
/// each whitespace-delimited word independently and deliberately does not use
/// whole-string normalization's multi-word merges. Insertions only mark their
/// own source string, so no word is copied into the other ayah.
final class AyahComparisonAligner {
  const AyahComparisonAligner();

  AyahComparisonAlignment align({
    required String leftText,
    required String rightText,
  }) {
    final left = _segments(leftText);
    final right = _segments(rightText);
    final leftWords = _recitable(left);
    final rightWords = _recitable(right);
    for (final pair in _alignWords(leftWords, rightWords)) {
      _markPair(pair, leftWords, rightWords);
    }
    return AyahComparisonAlignment(left: _spans(left), right: _spans(right));
  }

  List<_Segment> _segments(String text) {
    final result = <_Segment>[];
    var cursor = 0;
    for (final match in RegExp(r'\S+').allMatches(text)) {
      if (cursor < match.start) result.add(_Segment(cursor, match.start));
      final normalized = ArabicNormalizer.normalize(match.group(0)!);
      result.add(
        _Segment(
          match.start,
          match.end,
          normalized: RecitationWordDiffer.isRecitableWord(normalized)
              ? normalized
              : null,
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) result.add(_Segment(cursor, text.length));
    return result;
  }

  List<_Segment> _recitable(List<_Segment> segments) =>
      segments.where((segment) => segment.normalized != null).toList();

  List<_WordPair> _alignWords(List<_Segment> left, List<_Segment> right) {
    final dp = _distanceTable(left, right);
    return _backtrack(dp, left, right);
  }

  List<List<int>> _distanceTable(List<_Segment> left, List<_Segment> right) {
    final table = List.generate(
      left.length + 1,
      (i) => List<int>.generate(
        right.length + 1,
        (j) => i == 0
            ? j
            : j == 0
            ? i
            : 0,
      ),
    );
    for (var i = 1; i <= left.length; i++) {
      for (var j = 1; j <= right.length; j++) {
        final substitution = left[i - 1].normalized == right[j - 1].normalized
            ? 0
            : 1;
        table[i][j] = _min3(
          table[i - 1][j] + 1,
          table[i][j - 1] + 1,
          table[i - 1][j - 1] + substitution,
        );
      }
    }
    return table;
  }

  List<_WordPair> _backtrack(
    List<List<int>> table,
    List<_Segment> left,
    List<_Segment> right,
  ) {
    final reversed = <_WordPair>[];
    var i = left.length;
    var j = right.length;
    // Ties resolve in this fixed order: match, substitution, deletion, then
    // insertion. That makes repeated-word rendering reproducible.
    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          table[i][j] == table[i - 1][j - 1] &&
          left[i - 1].normalized == right[j - 1].normalized) {
        reversed.add(_WordPair(left: i - 1, right: j - 1));
        i--;
        j--;
      } else if (i > 0 && j > 0 && table[i][j] == table[i - 1][j - 1] + 1) {
        reversed.add(_WordPair(left: i - 1, right: j - 1));
        i--;
        j--;
      } else if (i > 0 && table[i][j] == table[i - 1][j] + 1) {
        reversed.add(_WordPair(left: i - 1));
        i--;
      } else {
        reversed.add(_WordPair(right: j - 1));
        j--;
      }
    }
    return reversed.reversed.toList(growable: false);
  }

  void _markPair(_WordPair pair, List<_Segment> left, List<_Segment> right) {
    final leftSegment = pair.left == null ? null : left[pair.left!];
    final rightSegment = pair.right == null ? null : right[pair.right!];
    final matches =
        leftSegment != null &&
        rightSegment != null &&
        leftSegment.normalized == rightSegment.normalized;
    if (leftSegment != null) {
      leftSegment.status = matches
          ? AyahComparisonSpanStatus.match
          : AyahComparisonSpanStatus.different;
    }
    if (rightSegment != null) {
      rightSegment.status = matches
          ? AyahComparisonSpanStatus.match
          : AyahComparisonSpanStatus.different;
    }
  }

  List<AyahComparisonSpan> _spans(List<_Segment> segments) =>
      List.unmodifiable([
        for (final segment in segments)
          AyahComparisonSpan(
            start: segment.start,
            end: segment.end,
            status: segment.status,
          ),
      ]);
}

final class _Segment {
  _Segment(this.start, this.end, {this.normalized})
    : status = AyahComparisonSpanStatus.nonrecitable;

  final int start;
  final int end;
  final String? normalized;
  AyahComparisonSpanStatus status;
}

final class _WordPair {
  const _WordPair({this.left, this.right});

  final int? left;
  final int? right;
}

int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
