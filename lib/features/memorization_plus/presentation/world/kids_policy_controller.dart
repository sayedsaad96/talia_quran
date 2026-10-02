import 'package:flutter/foundation.dart';

import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/kids_child_policy.dart';

typedef KidsChildPolicyLoader = Future<KidsChildPolicy> Function();

/// Current guardian policy for the kids path on this device.
///
/// Starts at the default policy and never loads on its own; callers invoke
/// [reload] (on entering the kids world, after a sync, after an edit).
///
/// App-lifetime DI singleton: widgets must never call `dispose()` on
/// `getIt<KidsPolicyController>()`.
class KidsPolicyController extends ValueNotifier<KidsChildPolicy> {
  KidsPolicyController({required KidsChildPolicyLoader load})
    : _load = load,
      super(const KidsChildPolicy());

  final KidsChildPolicyLoader _load;
  bool _disposed = false;
  int _generation = 0;

  /// Re-reads the policy. A load error keeps the previous value; a result
  /// superseded by a newer [reload] is dropped.
  Future<void> reload() async {
    if (_disposed) return;
    final generation = ++_generation;
    final KidsChildPolicy policy;
    try {
      policy = await _load();
    } catch (error, stack) {
      TaliaLogger.w('Kids child policy unavailable', error, stack);
      return;
    }
    if (_disposed || generation != _generation) return;
    value = policy;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
