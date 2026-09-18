/// Sound selection for prayer-time notifications.
/// System sound or the bundled athan clip from the `awqat` package
/// (Android `res/raw/adhan.mp3`, iOS bundle `adhan.caf`).
enum PrayerSoundMode { system, athan }

class ResolvedPrayerSound {
  const ResolvedPrayerSound({
    required this.mode,
    required this.androidChannelId,
    required this.androidSoundName,
    required this.iOSSoundName,
  });

  final PrayerSoundMode mode;

  /// Android channels freeze their sound at creation, so the athan clip
  /// needs its own channel id; reusing the legacy id would keep the old
  /// sound on already-installed apps.
  final String androidChannelId;

  /// Raw-resource name without extension, null for the system default.
  final String? androidSoundName;

  /// Bundle file name with extension, null for the system default.
  final String? iOSSoundName;
}

ResolvedPrayerSound resolvePrayerSound({
  required bool athanEnabled,
  required String prayerKey,
}) {
  if (!athanEnabled) {
    return const ResolvedPrayerSound(
      mode: PrayerSoundMode.system,
      androidChannelId: 'talia_prayer_times',
      androidSoundName: null,
      iOSSoundName: null,
    );
  }
  // The package ships a single `adhan` clip. Fajr keeps its own entry so a
  // future fajr-specific asset (e.g. `adhan_fajr`) plugs in here without
  // touching the scheduler or notification service.
  final clip = _clipFor(prayerKey);
  return ResolvedPrayerSound(
    mode: PrayerSoundMode.athan,
    androidChannelId: 'talia_prayer_times_athan',
    androidSoundName: clip,
    iOSSoundName: '$clip.caf',
  );
}

/// Bundled clip per prayer. Only `adhan` exists today; fajr is listed
/// explicitly as the seam for a distinct fajr recording.
String _clipFor(String prayerKey) =>
    const {'fajr': 'adhan'}[prayerKey] ?? 'adhan';
