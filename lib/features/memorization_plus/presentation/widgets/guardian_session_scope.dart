import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../application/guardian_session_controller.dart';

/// Keeps a guardian session on the child's device alive while the guardian
/// uses the dashboard. With [ownsSession] it also ends the session when the
/// dashboard closes or the app sleeps too long, and then returns to the kids
/// screen the guardian came from. Without a running session it does nothing.
class GuardianSessionScope extends StatefulWidget {
  const GuardianSessionScope({
    super.key,
    required this.child,
    this.ownsSession = false,
  });

  final Widget child;
  final bool ownsSession;

  @override
  State<GuardianSessionScope> createState() => _GuardianSessionScopeState();
}

class _GuardianSessionScopeState extends State<GuardianSessionScope>
    with WidgetsBindingObserver {
  GuardianSessionController? _session;
  String? _returnLocation;

  @override
  void initState() {
    super.initState();
    final session = getIt.isRegistered<GuardianSessionController>()
        ? getIt<GuardianSessionController>()
        : null;
    if (session == null || !session.isActive) return;
    _session = session;
    if (!widget.ownsSession) return;
    _returnLocation = session.returnLocation;
    WidgetsBinding.instance.addObserver(this);
    session.addListener(_onSessionChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _session?.appPaused();
      case AppLifecycleState.resumed:
        _session?.appResumed();
      default:
        break;
    }
  }

  void _onSessionChanged() {
    final session = _session;
    if (session == null || session.isActive || !mounted) return;
    session.removeListener(_onSessionChanged);
    _session = null;
    GoRouter.maybeOf(
      context,
    )?.go(_returnLocation ?? AppRoutes.memorizationPlusKidsHome);
  }

  @override
  void dispose() {
    final session = _session;
    if (session != null && widget.ownsSession) {
      WidgetsBinding.instance.removeObserver(this);
      session.removeListener(_onSessionChanged);
      session.end();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => session.touch(),
      child: widget.child,
    );
  }
}
