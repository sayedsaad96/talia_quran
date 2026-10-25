import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_quran_row_layout.dart';

void main() {
  const rowSize = Size(400, 200);

  KidsQuranRowLayout layoutFor({
    int index = 0,
    Size size = rowSize,
    TextDirection direction = TextDirection.ltr,
    bool showJuz = false,
  }) => kidsQuranRowLayout(
    index: index,
    size: size,
    direction: direction,
    showJuz: showJuz,
  );

  group('kidsQuranRowLayout', () {
    test('index 0 LTR puts the island on the start (left) with inset 16', () {
      final layout = layoutFor();
      expect(layout.island.left, 16);
      expect(layout.island.width, 160); // min(400 * 0.40, 180)
      expect(layout.island.height, 128); // width * 0.8
      expect(layout.island.bottom, 192); // bottom inset 8
    });

    test('index 0 RTL puts the island on the start (right)', () {
      final layout = layoutFor(direction: TextDirection.rtl);
      expect(layout.island.right, 384); // 400 - 16
      expect(layout.island.left, 224);
    });

    test('index 1 mirrors index 0', () {
      final even = layoutFor(index: 0);
      final odd = layoutFor(index: 1);
      expect(odd.island.right, 384);
      expect(odd.island.left, rowSize.width - even.island.right);
      expect(odd.card.left, rowSize.width - even.card.right);
      expect(odd.card.right, rowSize.width - even.card.left);
      expect(odd.taliaFoot.dx, rowSize.width - even.taliaFoot.dx);
    });

    test('card overlaps the island horizontally and stays inside the row', () {
      for (final index in [0, 1]) {
        for (final direction in TextDirection.values) {
          final layout = layoutFor(index: index, direction: direction);
          final overlap = layout.card.intersect(layout.island).width;
          expect(overlap, greaterThan(0), reason: 'index $index $direction');
          expect(layout.card.left, greaterThanOrEqualTo(0));
          expect(layout.card.right, lessThanOrEqualTo(rowSize.width));
          expect(layout.card.top, greaterThanOrEqualTo(0));
          expect(layout.card.bottom, lessThanOrEqualTo(rowSize.height));
          expect(layout.card.height, 104);
          // Centred 12 below the row centre.
          expect(layout.card.center.dy, rowSize.height / 2 + 12);
        }
      }
    });

    test('taliaFoot is the island top-centre nudged 12 down, inside the '
        'island', () {
      for (final index in [0, 1]) {
        for (final direction in TextDirection.values) {
          final layout = layoutFor(index: index, direction: direction);
          expect(layout.taliaFoot.dy, layout.island.top + 12);
          expect(layout.taliaFoot.dx, layout.island.center.dx);
          expect(
            layout.island.contains(layout.taliaFoot),
            isTrue,
            reason: 'index $index $direction',
          );
        }
      }
    });

    test('island width caps at 180 on wide rows', () {
      final layout = layoutFor(size: const Size(800, 200));
      expect(layout.island.width, 180);
      expect(layout.island.height, 144);
    });

    test('juzRibbon is null when showJuz is false', () {
      expect(layoutFor(showJuz: false).juzRibbon, isNull);
    });

    test('juzRibbon is 120x28 at the top, above the card far edge', () {
      for (final index in [0, 1]) {
        for (final direction in TextDirection.values) {
          final layout = layoutFor(
            index: index,
            direction: direction,
            showJuz: true,
          );
          final ribbon = layout.juzRibbon!;
          expect(ribbon.width, 120);
          expect(ribbon.height, 28);
          expect(ribbon.top, 0);
          // The card far edge is the edge away from the island.
          final cardFarEdge = index.isEven == (direction == TextDirection.ltr)
              ? layout.card.right
              : layout.card.left;
          expect(
            cardFarEdge == ribbon.right || cardFarEdge == ribbon.left,
            isTrue,
            reason: 'index $index $direction',
          );
        }
      }
    });
  });
}
