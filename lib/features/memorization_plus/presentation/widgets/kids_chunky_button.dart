import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// Colour roles for kids buttons: each step of a session has its own tone.
enum KidsButtonTone { gold, green, purple, soft }

class _ToneColors {
  const _ToneColors({
    required this.face,
    required this.base,
    required this.foreground,
  });

  final Color face;
  final Color base;
  final Color foreground;

  static _ToneColors of(KidsButtonTone tone, {required bool enabled}) {
    final colors = switch (tone) {
      KidsButtonTone.gold => const _ToneColors(
        face: KidsTheme.goldStar,
        base: KidsTheme.buttonGoldBase,
        foreground: KidsTheme.nightSkyDark,
      ),
      KidsButtonTone.green => const _ToneColors(
        face: KidsTheme.buttonGreenFace,
        base: KidsTheme.buttonGreenBase,
        foreground: Colors.white,
      ),
      KidsButtonTone.purple => const _ToneColors(
        face: KidsTheme.reviewPurple,
        base: KidsTheme.buttonPurpleBase,
        foreground: Colors.white,
      ),
      KidsButtonTone.soft => const _ToneColors(
        face: KidsTheme.creamParchment,
        base: KidsTheme.buttonSoftBase,
        foreground: KidsTheme.inkOnParchment,
      ),
    };
    if (enabled) return colors;
    // Disabled stays readable on the bright scene instead of vanishing.
    return _ToneColors(
      face: Color.lerp(colors.face, KidsTheme.buttonDisabledFace, 0.65)!,
      base: Color.lerp(colors.base, KidsTheme.buttonDisabledBase, 0.65)!,
      foreground: KidsTheme.inkOnParchment.withValues(alpha: 0.55),
    );
  }
}

/// A raised "candy" button for the kids path: a coloured face sits on a
/// darker base and sinks into it when pressed.
class KidsChunkyButton extends StatefulWidget {
  const KidsChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = KidsButtonTone.green,
    this.height = 64,
    this.maxLines = 2,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final KidsButtonTone tone;
  final double height;
  final int maxLines;

  static const double depth = 6;

  @override
  State<KidsChunkyButton> createState() => _KidsChunkyButtonState();
}

class _KidsChunkyButtonState extends State<KidsChunkyButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_enabled) return;
    unawaited(HapticFeedback.lightImpact());
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ToneColors.of(widget.tone, enabled: _enabled);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    const depth = KidsChunkyButton.depth;
    const radius = BorderRadius.all(Radius.circular(AppSpacing.radiusXl));

    final face = Container(
      constraints: BoxConstraints(minHeight: widget.height),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(colors.face, Colors.white, 0.18)!, colors.face],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: _enabled ? 0.35 : 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.28),
              ),
              child: Icon(widget.icon, color: colors.foreground, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleMedium.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled ? _handleTap : null,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _pressed ? depth - 2 : 0),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 90),
          builder: (context, sink, child) => Padding(
            padding: EdgeInsets.only(top: sink),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.base,
                borderRadius: radius,
                boxShadow: _enabled ? KidsTheme.card25DShadow : null,
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: depth - sink),
                child: child,
              ),
            ),
          ),
          child: face,
        ),
      ),
    );
  }
}

/// A big round play / microphone button with a label underneath. While
/// [active] (audio playing, voice recording) soft rings pulse around it.
class KidsRoundActionButton extends StatefulWidget {
  const KidsRoundActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tone = KidsButtonTone.gold,
    this.active = false,
    this.diameter = 92,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final KidsButtonTone tone;
  final bool active;
  final double diameter;

  @override
  State<KidsRoundActionButton> createState() => _KidsRoundActionButtonState();
}

class _KidsRoundActionButtonState extends State<KidsRoundActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rings;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _rings = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRings();
  }

  @override
  void didUpdateWidget(KidsRoundActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncRings();
  }

  void _syncRings() {
    final animate = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      if (!_rings.isAnimating) unawaited(_rings.repeat());
    } else {
      _rings
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _rings.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ToneColors.of(widget.tone, enabled: _enabled);
    final diameter = widget.diameter;
    const depth = KidsChunkyButton.depth;
    final ringExtent = diameter * 0.45;

    final button = AnimatedSlide(
      offset: Offset(0, _pressed ? 0.04 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 90),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [Color.lerp(colors.face, Colors.white, 0.3)!, colors.face],
          ),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: colors.base,
              offset: Offset(0, _pressed ? 2 : depth),
            ),
            if (_enabled) ...KidsTheme.card25DShadow,
          ],
        ),
        child: Icon(
          widget.icon,
          size: diameter * 0.48,
          color: colors.foreground,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _enabled
            ? () {
                unawaited(HapticFeedback.mediumImpact());
                widget.onPressed!();
              }
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: diameter + ringExtent,
              height: diameter + ringExtent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.active)
                    AnimatedBuilder(
                      animation: _rings,
                      builder: (context, _) => CustomPaint(
                        size: Size.square(diameter + ringExtent),
                        painter: _PulseRingsPainter(
                          progress: _rings.value,
                          color: colors.face,
                          innerRadius: diameter / 2,
                        ),
                      ),
                    ),
                  button,
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: KidsTheme.creamParchment,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: KidsTheme.card25DShadow,
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: AppTypography.titleSmall.copyWith(
                  color: KidsTheme.inkOnParchment.withValues(
                    alpha: _enabled ? 1 : 0.55,
                  ),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseRingsPainter extends CustomPainter {
  const _PulseRingsPainter({
    required this.progress,
    required this.color,
    required this.innerRadius,
  });

  final double progress;
  final Color color;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxGrowth = size.shortestSide / 2 - innerRadius;
    for (var ring = 0; ring < 2; ring++) {
      final t = (progress + ring * 0.5) % 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * (1 - t) + 1
        ..color = color.withValues(alpha: 0.55 * (1 - t));
      canvas.drawCircle(center, innerRadius + maxGrowth * t, paint);
    }
  }

  @override
  bool shouldRepaint(_PulseRingsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
