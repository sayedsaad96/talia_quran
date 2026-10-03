import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/kids_child_policy.dart';
import '../world/kids_policy_controller.dart';

import 'dart:async';

/// Applies the most restrictive motion preference to a kids-path subtree.
///
/// The guardian policy is app-lifetime state owned by DI. The scope reloads it
/// when a child enters this path, listens for live changes, and deliberately
/// never disposes it.
class KidsMotionScope extends StatefulWidget {
  const KidsMotionScope({super.key, required this.child});

  final Widget child;

  @override
  State<KidsMotionScope> createState() => _KidsMotionScopeState();
}

class _KidsMotionScopeState extends State<KidsMotionScope> {
  KidsPolicyController? _policy;

  @override
  void initState() {
    super.initState();
    if (!getIt.isRegistered<KidsPolicyController>()) return;
    _policy = getIt<KidsPolicyController>();
    // Deep links can enter a child surface before the home cubit has loaded
    // the guardian policy. The controller drops stale concurrent reloads.
    unawaited(_policy!.reload());
  }

  @override
  Widget build(BuildContext context) {
    final policy = _policy;
    if (policy == null) return widget.child;

    return ValueListenableBuilder<KidsChildPolicy>(
      valueListenable: policy,
      // Keep the child outside the listenable builder so a live guardian
      // toggle does not replace stateful reader or memorization subtrees.
      child: widget.child,
      builder: (context, value, child) {
        final mediaQuery =
            MediaQuery.maybeOf(context) ?? const MediaQueryData();
        final disableAnimations =
            mediaQuery.disableAnimations || value.reduceMotion;
        return MediaQuery(
          data: mediaQuery.copyWith(disableAnimations: disableAnimations),
          child: child!,
        );
      },
    );
  }
}
