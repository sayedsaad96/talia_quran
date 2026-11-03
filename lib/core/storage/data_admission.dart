import 'package:flutter/services.dart';

enum DataAdmissionMode { probe, foreground, worker, maintenance }

/// Injectable native transport. Every response must come from the issuing engine.
abstract interface class DataAdmissionPlatform {
  Future<String?> acquire(DataAdmissionMode mode);
  Future<bool> validate(String token);
  Future<bool> release(String token);
}

class MethodChannelDataAdmissionPlatform implements DataAdmissionPlatform {
  const MethodChannelDataAdmissionPlatform();
  static const _channel = MethodChannel('talia/data_admission');
  @override
  Future<String?> acquire(DataAdmissionMode mode) async {
    try {
      final token = await _channel.invokeMethod<String>('acquire', {
        'mode': mode.name,
      });
      return token == null || token.isEmpty ? null : token;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> validate(String token) async {
    try {
      return await _channel.invokeMethod<bool>('validate', {'token': token}) ==
          true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> release(String token) async {
    try {
      return await _channel.invokeMethod<bool>('release', {'token': token}) ==
          true;
    } catch (_) {
      return false;
    }
  }
}

/// Cross-engine/process lock admission; unsupported platforms fail closed.
class DataAdmission {
  DataAdmission({DataAdmissionPlatform? platform})
    : _platform = platform ?? const MethodChannelDataAdmissionPlatform();
  static final DataAdmission instance = DataAdmission();
  final DataAdmissionPlatform _platform;
  Future<DataAdmissionPermit?> acquireProbe() =>
      _acquire(DataAdmissionMode.probe);
  Future<DataAdmissionPermit?> acquireForeground() =>
      _acquire(DataAdmissionMode.foreground);
  Future<DataAdmissionPermit?> acquireWorker() =>
      _acquire(DataAdmissionMode.worker);
  Future<DataAdmissionPermit?> acquireMaintenance() =>
      _acquire(DataAdmissionMode.maintenance);
  Future<DataAdmissionPermit?> _acquire(DataAdmissionMode mode) async {
    try {
      final token = await _platform.acquire(mode);
      if (token == null || token.isEmpty) return null;
      final permit = DataAdmissionPermit._(_platform, token, mode);
      if (await permit.validate()) return permit;
      if (mode != DataAdmissionMode.foreground) {
        try {
          await permit.release();
        } catch (_) {
          /* Remain fail closed. */
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class DataAdmissionPermit {
  DataAdmissionPermit._(this._platform, this._token, this.mode);
  final DataAdmissionPlatform _platform;
  final String _token;
  final DataAdmissionMode mode;
  bool _released = false;
  Future<bool> validate() async {
    if (_released) return false;
    try {
      return await _platform.validate(_token);
    } catch (_) {
      return false;
    }
  }

  Future<void> release() async {
    if (mode == DataAdmissionMode.foreground) {
      throw StateError('Foreground admission is process lifetime');
    }
    if (_released) return;
    if (!await _platform.release(_token)) {
      throw StateError('Could not release admission');
    }
    _released = true;
  }
}
