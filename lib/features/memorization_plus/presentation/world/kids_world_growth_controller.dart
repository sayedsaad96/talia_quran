import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/talia_logger.dart';
import '../../domain/services/kids_world_growth_snapshot.dart';

/// The kids world's decorative growth, read from the milestones already
/// stored for the current owner. It stays [KidsWorldGrowthSnapshot.none]
/// while the feature is off, and an unreadable store shows no growth
/// instead of failing the screen.
class KidsWorldGrowthController extends ValueNotifier<KidsWorldGrowthSnapshot> {
  KidsWorldGrowthController({
    required Map<String, DateTime> Function() unlockedAchievements,
    required this._enabled,
    this._changes,
  }) : _unlocked = unlockedAchievements,
       super(KidsWorldGrowthSnapshot.none);

  final Map<String, DateTime> Function() _unlocked;
  final bool Function() _enabled;
  final Stream<void>? _changes;
  StreamSubscription<void>? _subscription;
  bool _disposed = false;

  /// Re-reads on every call (a cheap preferences read) so a screen opened after an
  /// account switch shows that owner's world; subscribes once to changes.
  /// The read runs in a microtask: callers start it from initState, and a
  /// changed value must not rebuild other listeners in the middle of a build.
  void ensureStarted() {
    if (_disposed) return;
    _subscription ??= _changes?.listen((_) => refresh());
    scheduleMicrotask(refresh);
  }

  void refresh() {
    if (_disposed) return;
    if (!_enabled()) {
      value = KidsWorldGrowthSnapshot.none;
      return;
    }
    try {
      value = buildKidsWorldGrowthSnapshot(
        KidsWorldGrowthEvidence(unlockedAchievements: _unlocked()),
      );
    } catch (error, stack) {
      TaliaLogger.w('Kids world growth unavailable', error, stack);
      value = KidsWorldGrowthSnapshot.none;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
