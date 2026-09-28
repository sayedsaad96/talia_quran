import 'package:flutter/material.dart';

import 'share_card_palette.dart';
import 'talia_share_tokens.dart';

/// Sky, golden mushaf light, optional watermark word and the logo's arch
/// as one hairline — the whole Dawn atmosphere, nothing else.
class ShareCardBackdrop extends StatelessWidget {
  const ShareCardBackdrop({
    super.key,
    required this.palette,
    required this.metrics,
    this.watermark,
  });

  final SharePalette palette;
  final TaliaShareMetrics metrics;
  final String? watermark;

  @override
  Widget build(BuildContext context) {
    final mark = watermark?.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.skyTop, palette.skyMid, palette.skyBase],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        DecoratedBox(
          key: const ValueKey('share-mushaf-light'),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.bottomCenter,
              radius: palette.glowRadius,
              colors: [
                palette.glow.withValues(alpha: palette.glowStrength),
                palette.glow.withValues(alpha: palette.glowStrength * 0.35),
                palette.glow.withValues(alpha: 0),
              ],
              stops: const [0, 0.4, 1],
            ),
          ),
        ),
        if (mark != null && mark.isNotEmpty)
          Align(
            alignment: const Alignment(0, -0.55),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: metrics.padding.left),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  mark,
                  key: const ValueKey('share-watermark'),
                  maxLines: 1,
                  style: TaliaShareTypography.display(
                    color: palette.watermark,
                    fontSize: metrics.watermarkSize,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        CustomPaint(
          key: const ValueKey('share-arch-hairline'),
          painter: ShareArchPainter(
            color: palette.archLine,
            bottomInset:
                metrics.signatureHeight + metrics.padding.bottom + metrics.gap,
          ),
        ),
      ],
    );
  }
}

/// The pointed mihrab arch from the Talia logo, as a single stroke.
class ShareArchPainter extends CustomPainter {
  const ShareArchPainter({required this.color, required this.bottomInset});

  final Color color;
  final double bottomInset;

  static Path archPath(Size size, {required double bottomInset}) {
    final left = size.width * 0.09;
    final right = size.width * 0.91;
    final w = right - left;
    final top = size.height * 0.09;
    final bottom = size.height - bottomInset;
    final shoulder = top + w * 0.46;
    double x(double f) => left + w * f;
    return Path()
      ..moveTo(left, bottom)
      ..lineTo(left, shoulder)
      ..quadraticBezierTo(left, top + w * 0.22, x(0.26), top + w * 0.14)
      ..quadraticBezierTo(x(0.46), top + w * 0.09, x(0.5), top)
      ..quadraticBezierTo(x(0.54), top + w * 0.09, x(0.74), top + w * 0.14)
      ..quadraticBezierTo(right, top + w * 0.22, right, shoulder)
      ..lineTo(right, bottom);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      archPath(size, bottomInset: bottomInset),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant ShareArchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.bottomInset != bottomInset;
}
