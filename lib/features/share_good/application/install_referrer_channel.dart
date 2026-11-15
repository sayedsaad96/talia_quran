import 'dart:async';

import 'package:flutter/services.dart';

class InstallReferrerChannel {
  const InstallReferrerChannel();

  static const _channel = MethodChannel('talia/install_referrer');

  Future<String?> readOnce() async {
    try {
      return await _channel
          .invokeMethod<String>('getReferrer')
          .timeout(const Duration(seconds: 4));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    } on TimeoutException {
      return null;
    }
  }
}
