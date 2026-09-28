import 'package:flutter/material.dart';

import '../share_card_palette.dart';
import '../talia_share_tokens.dart';

/// Large Kufi numeral. Digits stay left-to-right in both locales so
/// values such as "12 / 15" read correctly.
class HeroNumeral extends StatelessWidget {
  const HeroNumeral({
    super.key,
    required this.text,
    required this.color,
    required this.size,
  });

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      key: const ValueKey('share-hero-numeral'),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: TaliaShareTypography.display(
        color: color,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.05,
      ),
    );
  }
}

/// Thin progress line; [value] is clamped to 0..1 by the caller.
class HeroProgressLine extends StatelessWidget {
  const HeroProgressLine({
    super.key,
    required this.value,
    required this.palette,
    required this.width,
  });

  final double value;
  final SharePalette palette;
  final double width;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TaliaShareMetrics.barRadius);
    return Container(
      key: const ValueKey('share-progress-line'),
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: palette.textPrimary.withValues(alpha: 0.18),
        borderRadius: radius,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: value,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.textAccent,
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}
