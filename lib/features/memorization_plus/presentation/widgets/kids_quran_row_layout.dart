import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size, TextDirection;

/// Fixed height of one Quran-journey map row. A fixed extent keeps the
/// 114-row list cheap and lets the map open on the current surah with plain
/// arithmetic. Raised from 132 to 200 for the cartoon island rows.
const double kKidsQuranJourneyItemExtent = 200;

/// Where the island, card, juz ribbon and Talia's foot sit inside one row
/// of the Quran journey map. Pure geometry shared by the row, the road
/// painter and the Talia overlay.
class KidsQuranRowLayout {
  const KidsQuranRowLayout({
    required this.island,
    required this.card,
    required this.taliaFoot,
    required this.juzRibbon,
  });

  /// The island sprite area (directional start for even rows, end for odd).
  final Rect island;

  /// The parchment card, overlapping the island so it rests on it.
  final Rect card;

  /// Talia's anchor: the island top-centre nudged 12 px down.
  final Offset taliaFoot;

  /// The juz ribbon: a tab on the card's top near its far edge, or null
  /// when the row does not start a juz.
  final Rect? juzRibbon;
}

/// Lays out one journey-map row of [size] (its width is the row width, its
/// height the row height).
///
/// The island sits on the directional start for even rows and on the end for
/// odd rows, [direction]-aware. The card spans from 36% of the width on the
/// island side to the far edge minus 16, so it rests on the island's edge
/// while most of the island (and Talia on it) stays visible. The juz ribbon
/// is a tab on the card's top near its far edge when [showJuz] is true.
KidsQuranRowLayout kidsQuranRowLayout({
  required int index,
  required Size size,
  required TextDirection direction,
  required bool showJuz,
}) {
  final islandOnStart = index.isEven;
  final islandWidth = math.min(size.width * 0.40, 180.0);
  final islandHeight = islandWidth * 0.8;
  final islandBottom = size.height - 8;
  const startInset = 16.0;
  final islandLeft = islandOnStart
      ? (direction == TextDirection.rtl
            ? size.width - startInset - islandWidth
            : startInset)
      : (direction == TextDirection.rtl
            ? startInset
            : size.width - startInset - islandWidth);
  final island = Rect.fromLTWH(
    islandLeft,
    islandBottom - islandHeight,
    islandWidth,
    islandHeight,
  );

  final islandOnLeft = islandLeft <= size.width / 2;
  final cardTop = size.height / 2 + 12 - 104 / 2;
  final cardLeft = islandOnLeft ? size.width * 0.36 : startInset;
  final cardRight = islandOnLeft ? size.width - startInset : size.width * 0.64;
  final card = Rect.fromLTWH(cardLeft, cardTop, cardRight - cardLeft, 104);

  Rect? ribbon;
  if (showJuz) {
    // A tab on the card's top, inset from its far edge (the one away from
    // the island), overlapping the card by 6 so it labels this row only.
    final ribbonOnLeft = !islandOnLeft;
    ribbon = Rect.fromLTWH(
      ribbonOnLeft ? card.left + startInset : card.right - startInset - 120,
      card.top + 6 - 28,
      120,
      28,
    );
  }

  return KidsQuranRowLayout(
    island: island,
    card: card,
    taliaFoot: Offset(island.center.dx, island.top + 12),
    juzRibbon: ribbon,
  );
}
