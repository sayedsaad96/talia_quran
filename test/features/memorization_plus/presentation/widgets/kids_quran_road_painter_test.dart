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
}
