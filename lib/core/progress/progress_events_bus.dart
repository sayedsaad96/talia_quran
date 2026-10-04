import 'dart:async';

import 'progress_changed_reason.dart';

/// Broadcasts progress-domain writes so read-side cubits refresh without a
/// full app restart.
///
/// Writers call [notify] after every successful persistence. Listeners filter
/// by [ProgressChangedReason] to avoid unnecessary reloads (e.g. XP-only
/// updates skip the Progress tab full reload).
class ProgressEventsBus {
  ProgressEventsBus();

  final _controller = StreamController<ProgressChangedReason>.broadcast();

  Stream<ProgressChangedReason> get changes => _controller.stream;

  void notify(ProgressChangedReason reason) {
    if (!_controller.isClosed) {
      _controller.add(reason);
    }
  }

  /// Progress tab shows memorization, reading, streak, and certificates — not
  /// XP or the home activity feed.
  static bool affectsProgressTab(ProgressChangedReason reason) {
    return switch (reason) {
      ProgressChangedReason.xp => false,
      ProgressChangedReason.activityFeed => false,
      _ => true,
    };
  }

  /// Local-only changes that have nothing to upload.
  static bool requiresCloudPush(ProgressChangedReason reason) {
    return switch (reason) {
      ProgressChangedReason.cloudPull => false,
      ProgressChangedReason.activityFeed => false,
      _ => true,
    };
  }

  /// Home full reload is skipped for XP-only changes; use [refreshXp] instead.
  static bool affectsHomeFullReload(ProgressChangedReason reason) {
    return switch (reason) {
      ProgressChangedReason.xp => false,
      _ => true,
    };
  }

  void dispose() {
    _controller.close();
  }
}
