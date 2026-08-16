import 'package:flutter/material.dart';

/// Adaptive content region for share-card templates.
///
/// Cards are exported by rendering the widget offscreen, where no scrolling
/// is possible: a scrollable template would silently clip whatever falls
/// outside the first viewport in the exported PNG.  This widget instead lays
/// the template out at its natural height at the full content width and then
/// scales the whole block down to fit the shell's fixed region, so nothing is
/// ever cut off — shrinking is a uniform last resort rather than per-element
/// font shrinking.
///
/// The width is pinned (never the height) while measuring: a height cap would
/// make inner flexes overflow during layout before scaling could rescue them.
class ShareCardContent extends StatelessWidget {
  final Widget child;

  const ShareCardContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            child: child,
          ),
        );
      },
    );
  }
}
