import 'dart:io';

import 'package:flutter/services.dart';

/// Reads free app storage and whether the active network is unmetered from
/// the Android host. Every answer may be null: off Android, when the channel
/// fails, or when the device cannot tell. Callers treat null as unknown.
class DeviceResourceProbe {
  const DeviceResourceProbe({MethodChannel? channel, bool? isAndroid})
    : _channel = channel ?? const MethodChannel(channelName),
      _isAndroidOverride = isAndroid;

  static const channelName = 'talia/device_resources';

  final MethodChannel _channel;
  final bool? _isAndroidOverride;

  bool get _supported => _isAndroidOverride ?? Platform.isAndroid;

  /// Bytes available to the app in its private files directory.
  Future<int?> freeBytes() async {
    if (!_supported) return null;
    try {
      final value = await _channel.invokeMethod<Object?>('freeBytes');
      return value is int && value >= 0 ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// True on an unmetered network (normally Wi-Fi), false on a metered one.
  Future<bool?> isOnUnmeteredNetwork() async {
    if (!_supported) return null;
    try {
      final value = await _channel.invokeMethod<Object?>('isUnmeteredNetwork');
      return value is bool ? value : null;
    } catch (_) {
      return null;
    }
  }
}
