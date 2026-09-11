import 'package:flutter/material.dart';

/// Adaptive content region for share-card templates.
///
/// Cards are exported by rendering the widget offscreen, where no scrolling
/// is possible.  This widget lays out the template at its natural height
/// within the available width, then scales the **whole block down uniformly**
/// only when it overflows — nothing is ever clipped.
///
/// Templates supply adaptive font sizes for the supported content ranges;
/// this widget is only the final no-clipping safety net.
///
/// The width is pinned while measuring (never the height): a height cap would
/// cause inner flexes to overflow during layout before scaling could intervene.
class ShareCardContent extends StatelessWidget {
  final Widget child;

  const ShareCardContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return _ScaleToFit(availableWidth: constraints.maxWidth, child: child);
      },
    );
  }
}

/// Measures the child at [availableWidth], computes a scale factor to fit it
/// vertically into the parent's available height, then renders it scaled and
/// centered as a final safeguard against clipping.
class _ScaleToFit extends StatelessWidget {
  final Widget child;
  final double availableWidth;

  const _ScaleToFit({required this.child, required this.availableWidth});

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
