import 'dart:async';

import 'package:flutter/material.dart';

/// Removes this exact feedback route when its account/session expires.
/// Other dialogs above it remain untouched.
class V2FeedbackLifetimeGuard extends StatefulWidget {
  const V2FeedbackLifetimeGuard({
    super.key,
    required this.expiry,
    required this.isCurrent,
    required this.child,
  });
  final Stream<void>? expiry;
  final bool Function() isCurrent;
  final Widget child;

  @override
  State<V2FeedbackLifetimeGuard> createState() =>
      _V2FeedbackLifetimeGuardState();
}

class _V2FeedbackLifetimeGuardState extends State<V2FeedbackLifetimeGuard> {
  StreamSubscription<void>? _subscription;
  bool _dismissed = false;
  bool _expiryScheduled = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.expiry?.listen((_) => _expire(), onDone: _expire);
  }

  void _expire() {
    if (!mounted || _dismissed) return;
    _dismissed = true;
    final route = ModalRoute.of(context);
    if (route != null && route.isActive) route.navigator?.removeRoute(route);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCurrent()) return widget.child;
    if (!_expiryScheduled) {
      _expiryScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _expire());
    }
    return const SizedBox.shrink();
  }
}
