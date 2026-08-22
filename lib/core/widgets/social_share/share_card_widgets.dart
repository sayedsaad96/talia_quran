import 'package:flutter/material.dart';

import 'social_share_theme.dart';
import 'talia_share_tokens.dart';

/// Shared building blocks for the redesigned share-card templates.
///
/// These widgets keep the per-category templates visually distinct while
/// preventing the same medal/stat/chip compositions from being copy-pasted
/// between files. All of them are pure presentation — they only receive
/// already-localized strings and real `SocialShareData` values.

/// The official Talia companion, shown inline inside a template body.
///
/// Reserved for the (rare) adult opt-in path; kids cards compose the same
/// asset as a large hero inside the shared arch instead. Tagged with the
/// stable `share-character-image` key asserted by the widget tests.
class TaliaCharacterInline extends StatelessWidget {
  final String assetPath;
  final double height;

  const TaliaCharacterInline({
    super.key,
    required this.assetPath,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        key: const ValueKey('share-character-image'),
        assetPath,
        // Pin both axes so layout never depends on codec timing.
        width: height,
        height: height,
        fit: BoxFit.contain,
        cacheWidth: 288,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// A single real metric rendered as a gold-ringed medallion.
///
/// Used by the memorization, streak and progress families so numbers read as
/// jewelry-like milestones instead of plain text.
class StatMedallion extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color valueColor;
  final SocialShareTheme theme;
  final bool isCompact;
  final Color? ringColor;

  const StatMedallion({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.valueColor,
    required this.theme,
    this.isCompact = false,
    this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    final ring = ringColor ?? theme.accentColor;
    final size = isCompact ? 52.0 : 62.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.cardBackground,
            border: Border.all(color: ring.withValues(alpha: 0.85), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: ring.withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Faint outer halo ring for the jewelry feel.
              Container(
                width: size - 8,
                height: size - 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ring.withValues(alpha: 0.3),
                    width: 0.6,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: isCompact ? 11 : 13, color: ring),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TaliaShareTypography.metricValue(
                      color: valueColor,
                      fontSize: isCompact ? 16 : 19,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isCompact ? 76 : 92),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.badge(
              color: theme.textSecondary,
              fontSize: isCompact ? 8.5 : 9.5,
            ),
          ),
        ),
      ],
    );
  }
}

/// Thin gold rule with a small center ornament — a calmer divider than a
/// full pill for titles and footer separations.
class GoldDivider extends StatelessWidget {
  final Color color;
  final double width;

  const GoldDivider({super.key, required this.color, this.width = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 9,
      child: CustomPaint(painter: _GoldDividerPainter(color)),
    );
  }
}

class _GoldDividerPainter extends CustomPainter {
  final Color color;

  const _GoldDividerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 0.9;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);

    // Center diamond ornament.
    final cx = size.width / 2;
    final diamond = Path()
      ..moveTo(cx, y - 3.6)
      ..lineTo(cx + 3.6, y)
      ..lineTo(cx, y + 3.6)
      ..lineTo(cx - 3.6, y)
      ..close();
    canvas.drawPath(diamond, Paint()..color = color);
    canvas.drawCircle(
      Offset(cx - 9, y),
      1.1,
      Paint()..color = color.withValues(alpha: 0.7),
    );
    canvas.drawCircle(
      Offset(cx + 9, y),
      1.1,
      Paint()..color = color.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _GoldDividerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// An eight-point star ornament (two rotated squares), filled or outlined.
class ShareStarOrnament extends StatelessWidget {
  final Color color;
  final double size;
  final bool filled;

  const ShareStarOrnament({
    super.key,
    required this.color,
    required this.size,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _EightPointStarPainter(color, filled)),
    );
  }
}

class _EightPointStarPainter extends CustomPainter {
  final Color color;
  final bool filled;

  const _EightPointStarPainter(this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.78,
      height: size.height * 0.78,
    );
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, paint);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(45 * 3.14159265 / 180);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EightPointStarPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.filled != filled;
}

/// Gold-outlined reference chip used under Quran / Dua / Certificate heroes.
class ShareLabelChip extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;
  final bool isCompact;
  final List<Widget> children;

  const ShareLabelChip({
    super.key,
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
    this.isCompact = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 15,
        vertical: isCompact ? 3.5 : 4.5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: border.withValues(alpha: 0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 15, color: accent),
          const SizedBox(width: 6),
          ...children,
        ],
      ),
    );
  }
}

/// Open Quran emblem for the memorization family — two illuminated pages on
/// a gold ring, drawn rather than rastered so it follows the active theme.
class OpenQuranEmblem extends StatelessWidget {
  final SocialShareTheme theme;
  final double size;

  const OpenQuranEmblem({super.key, required this.theme, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OpenQuranPainter(
          gold: theme.accentColor,
          surface: theme.cardBackground,
          glow: theme.glowColor,
        ),
      ),
    );
  }
}

class _OpenQuranPainter extends CustomPainter {
  final Color gold;
  final Color surface;
  final Color glow;

  const _OpenQuranPainter({
    required this.gold,
    required this.surface,
    required this.glow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    // Outer ring with a soft halo.
    canvas.drawCircle(
      c,
      r * 0.98,
      Paint()..color = gold.withValues(alpha: 0.14),
    );
    final ring = Paint()
      ..color = gold.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(c, r * 0.86, ring);

    // Open book: two page curves meeting at a short spine.
    final page = Paint()
      ..color = surface.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final left = Path()
      ..moveTo(c.dx, c.dy + r * 0.42)
      ..quadraticBezierTo(
        c.dx - r * 0.55,
        c.dy + r * 0.28,
        c.dx - r * 0.72,
        c.dy + r * 0.06,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.4,
        c.dy - r * 0.22,
        c.dx,
        c.dy - r * 0.12,
      )
      ..close();
    final right = Path()
      ..moveTo(c.dx, c.dy + r * 0.42)
      ..quadraticBezierTo(
        c.dx + r * 0.55,
        c.dy + r * 0.28,
        c.dx + r * 0.72,
        c.dy + r * 0.06,
      )
      ..quadraticBezierTo(
        c.dx + r * 0.4,
        c.dy - r * 0.22,
        c.dx,
        c.dy - r * 0.12,
      )
      ..close();
    canvas.drawPath(left, page);
    canvas.drawPath(right, page);
    canvas.drawPath(left, outline);
    canvas.drawPath(right, outline);

    // Illuminated text lines on each page.
    final textLine = Paint()
      ..color = gold.withValues(alpha: 0.6)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    for (final dir in [-1.0, 1.0]) {
      for (var i = 0; i < 3; i++) {
        final y = c.dy - r * 0.02 + i * r * 0.14;
        final inset = r * (0.16 + i * 0.05);
        canvas.drawLine(
          Offset(c.dx + dir * inset, y),
          Offset(c.dx + dir * (r * 0.56 - i * r * 0.06), y),
          textLine,
        );
      }
    }

    // Small glow dot at the spine like a reading light.
    canvas.drawCircle(
      Offset(c.dx, c.dy - r * 0.34),
      1.6,
      Paint()..color = glow.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _OpenQuranPainter oldDelegate) =>
      oldDelegate.gold != gold ||
      oldDelegate.surface != surface ||
      oldDelegate.glow != glow;
}

/// Gentle hanging-lantern emblem for the Dua / Dhikr family.
class LanternEmblem extends StatelessWidget {
  final SocialShareTheme theme;
  final double size;

  const LanternEmblem({super.key, required this.theme, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HangingLanternPainter(
          gold: theme.accentColor,
          glow: TaliaShareColors.lanternGlow,
          lineFraction: 0.04,
        ),
      ),
    );
  }
}
