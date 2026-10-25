import 'dart:math' as math;
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

    test('taliaFoot is the island top-centre nudged 12 down (never higher '
        'than her height), inside the island', () {
      for (final index in [0, 1]) {
        for (final direction in TextDirection.values) {
          final layout = layoutFor(index: index, direction: direction);
          expect(
            layout.taliaFoot.dy,
            math.max(layout.island.top + 12, kKidsQuranTaliaSize),
          );
          expect(layout.taliaFoot.dx, layout.island.center.dx);
          expect(
            layout.island.contains(layout.taliaFoot),
            isTrue,
            reason: 'index $index $direction',
          );
        }
      }
    });

    test("Talia's head stays inside the row on wide screens", () {
      // At 450+ dp the island is 144 tall, so its top-centre + 12 would put
      // a 72 px Talia 12 px above the row (clipped on the first row).
      for (final width in [320.0, 400.0, 450.0, 800.0]) {
        final layout = layoutFor(size: Size(width, 200));
        expect(
          layout.taliaFoot.dy - kKidsQuranTaliaSize,
          greaterThanOrEqualTo(0),
          reason: 'width $width',
        );
        expect(layout.island.contains(layout.taliaFoot), isTrue);
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

    test('juzRibbon is a 120x28 tab on the card top, near its far edge', () {
      for (final index in [0, 1]) {
        for (final direction in TextDirection.values) {
          final layout = layoutFor(
            index: index,
            direction: direction,
            showJuz: true,
          );
          final ribbon = layout.juzRibbon!;
          final reason = 'index $index $direction';
          expect(ribbon.width, 120);
          expect(ribbon.height, 28);
          // Sits on the card it labels (overlapping its top by 6), so it
          // never reads as belonging to the row above.
          expect(ribbon.bottom, layout.card.top + 6, reason: reason);
          expect(ribbon.top, greaterThanOrEqualTo(0), reason: reason);
          // Inset 16 from the card's far edge (the edge away from the island).
          final farIsRight = index.isEven == (direction == TextDirection.ltr);
          if (farIsRight) {
            expect(ribbon.right, layout.card.right - 16, reason: reason);
          } else {
            expect(ribbon.left, layout.card.left + 16, reason: reason);
          }
        }
      }
    });

    test('the card leaves most of the island visible', () {
      for (final index in [0, 1]) {
        for (final direction in TextDirection.values) {
          final layout = layoutFor(index: index, direction: direction);
          final overlap = layout.card.intersect(layout.island).width;
          expect(
            overlap,
            lessThanOrEqualTo(layout.island.width * 0.25),
            reason: 'index $index $direction',
          );
          // Talia stands on the visible part, clear of the card.
          expect(
            layout.card.contains(layout.taliaFoot),
            isFalse,
            reason: 'index $index $direction',
          );
        }
      }
    });
  });
}
