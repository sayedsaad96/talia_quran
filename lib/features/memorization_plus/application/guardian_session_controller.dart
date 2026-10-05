import 'dart:async';

import 'package:flutter/foundation.dart';

/// A short guardian visit to the family dashboard on the child's own device.
///
/// It opens after the guardian PIN, keeps the child's identity untouched and
/// ends on its own after [idleTimeout] without interaction or when the app
/// stays in the background longer than [backgroundGrace].
class GuardianSessionController extends ChangeNotifier {
  GuardianSessionController({
    DateTime Function()? clock,
    this.idleTimeout = const Duration(minutes: 10),
    this.backgroundGrace = const Duration(minutes: 2),
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Duration idleTimeout;
  final Duration backgroundGrace;

  bool _active = false;
  String? _returnLocation;
  DateTime? _lastActivity;
  DateTime? _pausedAt;
  Timer? _idleTimer;

  bool get isActive {
    if (!_active) return false;
    final now = _clock();
    if (now.difference(_lastActivity!) >= idleTimeout) return false;
    final pausedAt = _pausedAt;
    return pausedAt == null || now.difference(pausedAt) <= backgroundGrace;
  }

  /// The kids screen the guardian came from.
  String? get returnLocation => _returnLocation;

  void start({required String returnLocation}) {
    _active = true;
    _returnLocation = returnLocation;
    _pausedAt = null;
    touch();
    notifyListeners();
  }

  /// Any guardian interaction pushes the idle deadline back.
  void touch() {
    if (!_active) return;
    _lastActivity = _clock();
    _armIdleTimer(idleTimeout);
  }

  void appPaused() {
    if (!_active) return;
    _pausedAt = _clock();
  }

  void appResumed() {
    if (!_active) return;
    if (!isActive) {
      end();
      return;
    }
    _pausedAt = null;
    _armIdleTimer(idleTimeout - _clock().difference(_lastActivity!));
  }

  void end() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (!_active) return;
    _active = false;
    _lastActivity = null;
    _pausedAt = null;
    notifyListeners();
  }

  void _armIdleTimer(Duration after) {
    _idleTimer?.cancel();
    _idleTimer = Timer(after, () {
      if (!isActive) end();
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
