import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Keeps system back inside the app for pages that can be reached with
/// `context.go` and so may be the only route on the stack.
///
/// With history, back pops as usual. Without it, back goes to
/// [fallbackLocation] instead of closing the app.
class FallbackPopScope extends StatelessWidget {
  const FallbackPopScope({
    super.key,
    required this.fallbackLocation,
    required this.child,
  });

  final String fallbackLocation;
  final Widget child;

  /// Whether back can pop a route. Falls back to the plain [Navigator] when
  /// no [GoRouter] is in scope (isolated widget tests).
  static bool hasHistory(BuildContext context) =>
      GoRouter.maybeOf(context)?.canPop() ?? Navigator.canPop(context);

  @override
  Widget build(BuildContext context) {
    if (GoRouter.maybeOf(context) == null) return child;
    return PopScope(
      canPop: hasHistory(context),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(fallbackLocation);
      },
      child: child,
    );
  }
}
