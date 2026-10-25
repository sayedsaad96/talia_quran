import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/screen_awake_service.dart';

/// Keeps the screen on while [child]'s route is the current one, for reading
/// screens where the user is not touching the device. Covering the route with
/// another one, or leaving it, lets the screen time out normally again.
class KeepScreenAwake extends StatefulWidget {
  const KeepScreenAwake({super.key, required this.child, this.service});

  final Widget child;

  /// Defaults to [ScreenAwakeService.instance].
  final ScreenAwakeService? service;

  @override
  State<KeepScreenAwake> createState() => _KeepScreenAwakeState();
}

class _KeepScreenAwakeState extends State<KeepScreenAwake> {
  bool _holding = false;

  ScreenAwakeService get _service =>
      widget.service ?? ScreenAwakeService.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depends on the route's status, so this reruns when it is covered or
    // uncovered. No route (e.g. a bare widget test) counts as current.
    _setHolding(ModalRoute.of(context)?.isCurrent ?? true);
  }

  @override
  void dispose() {
    _setHolding(false);
    super.dispose();
  }

  void _setHolding(bool hold) {
    if (hold == _holding) return;
    _holding = hold;
    unawaited(hold ? _service.acquire() : _service.release());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
