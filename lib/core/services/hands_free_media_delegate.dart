import 'package:audio_service/audio_service.dart';

abstract interface class HandsFreeMediaDelegate {
  void onPrimary();
  void onSecondary();
  void onInterrupted();
}

/// Capability belonging to one acquisition; release cannot detach another owner.
abstract interface class HandsFreeMediaLease {
  bool get isCurrent;
  void publish({required MediaItem item, required bool playing});
  Future<void> release();
}
