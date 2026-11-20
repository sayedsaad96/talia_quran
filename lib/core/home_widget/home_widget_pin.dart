import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asks Android to pin the home widget, checks installed count, or reports
/// when this launcher cannot pin.
///
/// `requestPin` returning false means the launcher has no pin sheet. The
/// settings screen then shows a preview and the manual steps instead.
final class HomeWidgetPin {
  HomeWidgetPin({
    this._isSupported,
    this.request,
    this._installedCount,
  });

  static const channel = MethodChannel('talia/home_widget_component');

  final Future<bool> Function()? _isSupported;
  final Future<bool> Function()? request;
  final Future<int> Function()? _installedCount;

  Future<bool> isSupported() async {
    final override = _isSupported;
    if (override != null) return override();
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await channel.invokeMethod<bool>('isPinSupported') == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPin() async {
    final override = request;
    if (override != null) return override();
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await channel.invokeMethod<bool>('requestPin') == true;
    } catch (_) {
      return false;
    }
  }

  /// Number of Talia widgets currently placed on the device home screen.
  Future<int> installedCount() async {
    final override = _installedCount;
    if (override != null) return override();
    if (kIsWeb || !Platform.isAndroid) return 0;
    try {
      final count = await channel.invokeMethod<int>('getInstalledCount');
      return count != null && count > 0 ? count : 0;
    } catch (_) {
      return 0;
    }
  }
}
