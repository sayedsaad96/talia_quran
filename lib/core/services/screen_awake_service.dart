import 'dart:io';

import 'package:flutter/services.dart';

/// Keeps the display on while at least one holder asks for it, through the
/// Android window's keep-screen-on flag. The flag only applies while the
/// app's window is visible, so it never holds a wake lock in the background
/// and needs no permission. Off Android, or when the channel fails, it is a
/// no-op: the screen simply follows the system timeout.
class ScreenAwakeService {
  ScreenAwakeService({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel(channelName),
      _isAndroidOverride = isAndroid;

  static const channelName = 'talia/screen_awake';

  /// Shared instance, so holders on different routes count together.
  static final ScreenAwakeService instance = ScreenAwakeService();

  final MethodChannel _channel;
  final bool? _isAndroidOverride;
  int _holders = 0;

  bool get _supported => _isAndroidOverride ?? Platform.isAndroid;

  bool get isHeld => _holders > 0;

  /// Adds a holder; the first one turns keep-screen-on on.
  Future<void> acquire() async {
    _holders++;
    if (_holders == 1) await _apply(true);
  }

  /// Removes a holder; the last one turns keep-screen-on off.
  Future<void> release() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) await _apply(false);
  }

  Future<void> _apply(bool enabled) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('setKeepScreenOn', {
        'enabled': enabled,
      });
    } catch (_) {
      // Best effort: a missing or failing host leaves the system timeout.
    }
  }
}
