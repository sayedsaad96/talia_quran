import 'package:flutter/widgets.dart';

/// The minimum logical width for the tablet two-page Mushaf layout.
const kSpreadMinWidthDp = 840.0;

/// Whether odd-numbered canonical Mushaf pages appear on the visual right.
///
/// This is the owner-approved R3 decision for Phase 3.
const kOddPageOnRight = true;

const _kCanonicalPageCount = 604;
const _kDefaultQuranSpreadPolicy = QuranSpreadPolicy();

/// Whether a two-page Mushaf layout is available in the current viewport.
bool shouldShowSpread({
  required double widthDp,
  required Orientation orientation,
  required bool enabled,
}) {
  return enabled &&
      orientation == Orientation.landscape &&
      widthDp >= kSpreadMinWidthDp;
}

/// Returns the visual spread containing [canonicalPage].
QuranSpread spreadForPage(int canonicalPage) {
  return _kDefaultQuranSpreadPolicy.spreadForPage(canonicalPage);
}

/// Returns the zero-based visual spread index containing [canonicalPage].
int spreadIndexForPage(int canonicalPage) {
  return _kDefaultQuranSpreadPolicy.spreadIndexForPage(canonicalPage);
}

/// Returns the visual spread at [index].
QuranSpread spreadAt(int index) {
  return _kDefaultQuranSpreadPolicy.spreadAt(index);
}

/// Returns the number of two-page spreads in the canonical Mushaf.
int spreadCount() => _kDefaultQuranSpreadPolicy.spreadCount();

/// Immutable policy for pairing canonical Mushaf pages into visual spreads.
///
/// The configurable parity keeps the page-pairing invariant testable without
/// changing the approved [kOddPageOnRight] decision.
final class QuranSpreadPolicy {
  const QuranSpreadPolicy({this.oddPageOnRight = kOddPageOnRight});

  final bool oddPageOnRight;

  QuranSpread spreadForPage(int canonicalPage) {
    _validatePage(canonicalPage);
    return spreadAt(spreadIndexForPage(canonicalPage));
  }

  int spreadIndexForPage(int canonicalPage) {
    _validatePage(canonicalPage);
    return (canonicalPage - 1) ~/ 2;
  }

  QuranSpread spreadAt(int index) {
    if (index < 0 || index >= spreadCount()) {
      throw RangeError.range(index, 0, spreadCount() - 1, 'index');
    }

    final firstPage = index * 2 + 1;
    final secondPage = firstPage + 1;
    return oddPageOnRight
        ? QuranSpread(rightPage: firstPage, leftPage: secondPage)
        : QuranSpread(rightPage: secondPage, leftPage: firstPage);
  }

  int spreadCount() => _kCanonicalPageCount ~/ 2;

  void _validatePage(int canonicalPage) {
    if (canonicalPage < 1 || canonicalPage > _kCanonicalPageCount) {
      throw RangeError.range(
        canonicalPage,
        1,
        _kCanonicalPageCount,
        'canonicalPage',
      );
    }
  }
}

/// A pair of canonical pages as they appear in a visual Mushaf spread.
final class QuranSpread {
  const QuranSpread({required this.rightPage, required this.leftPage});

  final int? rightPage;
  final int? leftPage;
}
