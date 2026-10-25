import 'dart:ui' show Offset, Path, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_quran_road_painter.dart';

KidsQuranRoadPainter _painter({
  double hereX = 100,
  double previousX = 40,
  double nextX = 160,
  bool isFirst = false,
  bool isLast = false,
  bool incomingLit = false,
  bool outgoingLit = false,
  bool night = false,
  int seed = 7,
  double shimmer = 0,
}) => KidsQuranRoadPainter(
  hereX: hereX,
  previousX: previousX,
  nextX: nextX,
  isFirst: isFirst,
  isLast: isLast,
  incomingLit: incomingLit,
  outgoingLit: outgoingLit,
  night: night,
  seed: seed,
  shimmer: shimmer,
);

void main() {
  group('KidsQuranRoadPainter.shouldRepaint', () {
    test('is true when only night changes', () {
      final old = _painter(night: false);
      final next = _painter(night: true);
      expect(next.shouldRepaint(old), isTrue);
    });

    test('is true when only incomingLit changes', () {
      final old = _painter(incomingLit: false);
      final next = _painter(incomingLit: true);
      expect(next.shouldRepaint(old), isTrue);
    });

    test('is true when only outgoingLit changes', () {
      final old = _painter(outgoingLit: false);
      final next = _painter(outgoingLit: true);
      expect(next.shouldRepaint(old), isTrue);
    });

    test('is false when nothing changes', () {
      final old = _painter(seed: 3, night: true, shimmer: 0.5);
      final next = _painter(seed: 3, night: true, shimmer: 0.5);
      expect(next.shouldRepaint(old), isFalse);
    });
  });

  group('KidsQuranRoadPainter road continuity', () {
    Offset first(Path path) =>
        path.computeMetrics().first.getTangentForOffset(0)!.position;
    Offset last(Path path) {
      final metric = path.computeMetrics().last;
      return metric.getTangentForOffset(metric.length)!.position;
    }

    test("a row's road leaves where the next row's road enters", () {
      const size = Size(400, 200);
      final row0 = _painter(hereX: 96, previousX: 0, nextX: 304, isFirst: true);
      final row1 = _painter(hereX: 304, previousX: 96, nextX: 96);
      final end = last(row0.outgoingPath(size));
      final start = first(row1.incomingPath(size));
      expect(end.dx, closeTo(start.dx, 0.01));
      expect(end.dy, closeTo(size.height, 0.01));
      expect(start.dy, closeTo(0, 0.01));
    });

    test('the coin sits low on the outgoing road, in the gap below the '
        'card', () {
      const size = Size(400, 200);
      final row = _painter(hereX: 96, previousX: 304, nextX: 304);
      final coin = row.coinCenter(size);
      // Cards end at 164 (centred 12 below the middle, 104 tall).
      expect(coin.dy, greaterThan(164 + 11));
      expect(coin.dy, lessThan(size.height));
      // On the road: between the foot and the boundary horizontally.
      expect(coin.dx, inInclusiveRange(96, 200));
    });

    test("the road passes through this row's foot", () {
      const size = Size(400, 200);
      final row = _painter(hereX: 304, previousX: 96, nextX: 96);
      expect(last(row.incomingPath(size)), const Offset(304, 100));
      expect(first(row.outgoingPath(size)), const Offset(304, 100));
    });
  });
}
