import 'dart:math' as math;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// MushafScrollPhysics
// ---------------------------------------------------------------------------
/// Uses Flutter's built-in [PageScrollPhysics] for reliable page snapping.
/// A previous custom spring implementation was underdamped (damping << critical
/// threshold) and caused infinite left-right oscillation. PageScrollPhysics
/// is battle-tested and snaps pages correctly on all devices.
typedef MushafScrollPhysics = PageScrollPhysics;

// ---------------------------------------------------------------------------
// MushafPageCurlOverlay
// ---------------------------------------------------------------------------
/// An [AnimatedBuilder]-friendly overlay that reads [pageOffset] (the
/// fractional scroll offset between pages, e.g. 0.0 = centred on a page,
/// ±0.5 = halfway between pages) and draws a soft page-curl shadow + gradient
/// on the leading edge, giving the visual impression of a book page turning.
class MushafPageCurlOverlay extends StatelessWidget {
  const MushafPageCurlOverlay({
    super.key,
    required this.pageOffsetNotifier,
    required this.child,
    this.pageColor = Colors.white,
    this.shadowColor = Colors.black,
  });

  final ValueNotifier<double> pageOffsetNotifier;
  final Widget child;
  final Color pageColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ValueListenableBuilder<double>(
              valueListenable: pageOffsetNotifier,
              builder: (context, offset, _) {
                // offset is fractional page position (e.g. 0.72 = 72% through page)
                final frac = offset - offset.truncate();
                if (frac < 0.01 || frac > 0.99) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _PageCurlPainter(
                    progress: frac,
                    pageColor: pageColor,
                    shadowColor: shadowColor,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _PageCurlPainter
// ---------------------------------------------------------------------------
/// Draws:
/// 1. A soft gradient shadow on the right edge of the "current" page (RTL: left edge)
/// 2. A subtle perspective-tilt bevel line where the page curls
///
/// [progress] is in [0, 1]: how far the page has been swiped (0 = no swipe,
/// 1 = fully turned). The effect is most visible between 0.05 and 0.95.
class _PageCurlPainter extends CustomPainter {
  _PageCurlPainter({
    required this.progress,
    required this.pageColor,
    required this.shadowColor,
  });

  final double progress;
  final Color pageColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    // --- Shadow gradient on the trailing (left) edge ---
    final shadowWidth = size.width * 0.12 * math.sin(progress * math.pi);
    if (shadowWidth < 1) return;

    final shadowRect = Rect.fromLTWH(0, 0, shadowWidth, size.height);
    final shadowGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        shadowColor.withValues(alpha: 0.30 * math.sin(progress * math.pi)),
        shadowColor.withValues(alpha: 0.0),
      ],
    );
    canvas.drawRect(
      shadowRect,
      Paint()..shader = shadowGradient.createShader(shadowRect),
    );

    // --- Highlight / bevel line on the turning page edge ---
    final bevelX = size.width * progress;
    if (bevelX > 0 && bevelX < size.width) {
      final bevelWidth = 8.0 * math.sin(progress * math.pi);
      final bevelRect = Rect.fromLTWH(
        bevelX - bevelWidth,
        0,
        bevelWidth * 2,
        size.height,
      );
      final bevelGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          pageColor.withValues(alpha: 0.0),
          pageColor.withValues(alpha: 0.55 * math.sin(progress * math.pi)),
          pageColor.withValues(alpha: 0.0),
        ],
      );
      canvas.drawRect(
        bevelRect,
        Paint()..shader = bevelGradient.createShader(bevelRect),
      );
    }
  }

  @override
  bool shouldRepaint(_PageCurlPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.pageColor != pageColor ||
      oldDelegate.shadowColor != shadowColor;
}
