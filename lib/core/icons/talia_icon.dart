import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/talia_tokens.dart';
import 'talia_icon_data.dart';

/// Which glyph family [TaliaIcon] draws below a [TaliaIconScope].
enum TaliaIconVariant { adult, kids }

/// Switches every [TaliaIcon] in its subtree to the kids variant (thicker
/// stroke, tinted fill, sparkle nuqta). Wrap kids-track pages in
/// [TaliaIconScope.kids]; everything else is adult by default.
class TaliaIconScope extends InheritedWidget {
  const TaliaIconScope({
    super.key,
    required this.variant,
    required super.child,
  });

  const TaliaIconScope.kids({super.key, required super.child})
    : variant = TaliaIconVariant.kids;

  final TaliaIconVariant variant;

  static TaliaIconVariant variantOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TaliaIconScope>()?.variant ??
      TaliaIconVariant.adult;

  @override
  bool updateShouldNotify(TaliaIconScope oldWidget) =>
      variant != oldWidget.variant;
}

/// Draws a [TaliaIcons] glyph with its Talia layers.
///
/// Drop-in for [Icon]: same positional icon and the same common named
/// arguments. On top of [Icon] it
/// - lights the nuqta (the rhombus accent of feature icons) in gold when
///   [active] is true; when false the nuqta keeps the icon colour, which is
///   how a plain `Icon(TaliaIcons.x)` looks too,
/// - picks the kids glyph, tint layer and sparkle inside
///   [TaliaIconScope.kids].
///
/// Non-Talia [IconData] render exactly like [Icon].
class TaliaIcon extends StatelessWidget {
  const TaliaIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.active = true,
    this.accentColor,
    this.fillColor,
    this.semanticLabel,
    this.shadows,
    this.textDirection,
  });

  final IconData? icon;
  final double? size;
  final Color? color;

  /// Whether the nuqta is lit (gold). Navigation passes the selected state.
  final bool active;

  /// Overrides the lit nuqta colour (defaults to the theme gold).
  final Color? accentColor;

  /// Overrides the kids tint layer colour (defaults to [color] at 24%).
  final Color? fillColor;
  final String? semanticLabel;
  final List<Shadow>? shadows;
  final TextDirection? textDirection;

  static const String _adultFamily = 'TaliaIcons';
  static const String _kidsFamily = 'TaliaIconsKids';

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    final family = icon?.fontFamily;
    if (icon == null || (family != _adultFamily && family != _kidsFamily)) {
      return _glyph(icon);
    }
    // TaliaKidsIcons are always kids; TaliaIcons follow the scope.
    final kids =
        family == _kidsFamily ||
        TaliaIconScope.variantOf(context) == TaliaIconVariant.kids;
    final cp = icon.codePoint;
    final base = kids ? (taliaKidsVariants[cp] ?? icon) : icon;
    final accent = kids ? taliaKidsAccentLayers[cp] : taliaAccentLayers[cp];
    final fill = kids ? taliaKidsFillLayers[cp] : null;

    final lit = active && accent != null;
    if (!lit && fill == null) return _glyph(base);

    final iconColor = color ?? IconTheme.of(context).color;
    final tokens = TaliaTokens.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        if (fill != null)
          ExcludeSemantics(
            child: _layer(
              fill,
              fillColor ?? iconColor?.withValues(alpha: 0.24),
            ),
          ),
        _glyph(base),
        if (lit)
          ExcludeSemantics(
            child: _layer(
              accent,
              accentColor ?? (kids ? AppColors.kidsSparkle : tokens.gold),
            ),
          ),
      ],
    );
  }

  Widget _glyph(IconData? data) => Icon(
    data,
    size: size,
    color: color,
    semanticLabel: semanticLabel,
    shadows: shadows,
    textDirection: textDirection,
  );

  Widget _layer(IconData data, Color? layerColor) =>
      Icon(data, size: size, color: layerColor, textDirection: textDirection);
}

/// Kids-track feature tile: a coloured arch "door" (Talia's logo arch)
/// holding a white kids glyph. Used where the kids track lists its places
/// (missions, journey, treasures, Quran) so each one gets its own colour.
class TaliaFeatureDoor extends StatelessWidget {
  const TaliaFeatureDoor({
    super.key,
    required this.icon,
    required this.color,
    this.size = 56,
    this.semanticLabel,
  });

  final IconData icon;

  /// Door colour; use one of the `AppColors.kidsDoor*` tones (all keep a
  /// white glyph at 3:1 or better).
  final Color color;

  /// Door width; the height is 1.1x.
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size * 1.1,
        child: CustomPaint(
          painter: _DoorPainter(color),
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.28, bottom: size * 0.1),
            child: Center(
              child: TaliaIconScope.kids(
                child: TaliaIcon(
                  icon,
                  size: size * 0.5,
                  color: Colors.white,
                  fillColor: Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoorPainter extends CustomPainter {
  const _DoorPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Same arch as the logo frame: flat base, pointed rounded top.
    final arch = Path()
      ..moveTo(w * 0.06, h * 0.92)
      ..lineTo(w * 0.06, h * 0.42)
      ..cubicTo(w * 0.06, h * 0.2, w * 0.28, h * 0.08, w * 0.5, h * 0.02)
      ..cubicTo(w * 0.72, h * 0.08, w * 0.94, h * 0.2, w * 0.94, h * 0.42)
      ..lineTo(w * 0.94, h * 0.92)
      ..close();
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.95),
        width: w * 0.8,
        height: h * 0.08,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawPath(arch, Paint()..color = color);
    canvas.drawPath(
      arch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.kidsInk.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_DoorPainter oldDelegate) => oldDelegate.color != color;
}
