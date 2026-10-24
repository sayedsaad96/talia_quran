import 'package:audio_service/audio_service.dart';

abstract interface class HandsFreeMediaDelegate {
  void onPrimary();
  void onSecondary();
  void onInterrupted();

  /// A physical media button. audio_service reports PLAY, PAUSE, PLAY_PAUSE
  /// and HEADSETHOOK alike, so an earbud removal is indistinguishable from a
  /// press; the delegate must let a following interruption cancel it.
  void onHardwareButton({required bool primary});
}

/// Capability belonging to one acquisition; release cannot detach another owner.
abstract interface class HandsFreeMediaLease {
  bool get isCurrent;
  void publish({required MediaItem item, required bool playing});
  Future<void> release();
}
