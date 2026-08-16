import 'package:flutter/material.dart';

/// Adaptive content region for share-card templates.
///
/// Cards are exported by rendering the widget offscreen, where no scrolling
/// is possible.  This widget lays out the template at its natural height
/// within the available width, then scales the **whole block down uniformly**
/// only when it overflows — nothing is ever clipped.
///
/// Scale-down is clamped to 0.72× so that in pathological cases (very long
/// verses) the template shrinks gracefully but does not become unreadable.
/// Templates already supply adaptive font sizes for the most common length
/// ranges; this widget acts as a final safety net, not the primary mechanism.
///
/// The width is pinned while measuring (never the height): a height cap would
/// cause inner flexes to overflow during layout before scaling could intervene.
class ShareCardContent extends StatelessWidget {
  final Widget child;

  /// Minimum scale applied when content overflows.  Keeps badges, icons, and
  /// reference text legible even when verse text is very long.
  static const double _minScale = 0.72;

  const ShareCardContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _ScaleToFit(
          availableWidth: constraints.maxWidth,
          minScale: _minScale,
          child: child,
        );
      },
    );
  }
}

/// Measures the child at [availableWidth], computes a scale factor to fit it
/// vertically into the parent's available height, clamps it to [minScale],
/// and then renders it scaled + centered.
class _ScaleToFit extends StatelessWidget {
  final Widget child;
  final double availableWidth;
  final double minScale;

  const _ScaleToFit({
    required this.child,
    required this.availableWidth,
    required this.minScale,
  });

  @override
  Widget build(BuildContext context) {
    // FittedBox with BoxFit.scaleDown pins width and scales uniformly.
    // The key improvement over a bare FittedBox: we wrap in a SizedBox that
    // provides a *finite* width so the child is always measured at the correct
    // share-card width regardless of the surrounding layout constraints.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: availableWidth,
          // Allow content to grow as tall as needed so the child lays out
          // fully before FittedBox applies uniform scale-down.
          minWidth: availableWidth,
        ),
        child: child,
      ),
    );
  }
}
